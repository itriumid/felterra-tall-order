class_name Online
extends Node
## Playing online: what the host and its guests say to each other. The host runs the world; each
## guest has their own screen on it, and plays their own cat in it.
##
## A guest says hello with what they bring from their own village (their coat, the weapons forged
## there, the cub if they have it), and waits. When the host goes out to Endless, each guest is
## told the run's seed and lays out the same clearing or grove; they choose what they start with,
## the host puts their cat in, and the run waits for everyone, as it does on one screen. In the
## run, a guest sends how they steer and what they press, and the host sends the world back, 20
## times a second. When the crew is down, each guest is sent the run's numbers, and waits for the
## next.
##
## How the packets travel is Session's business, not this.

## Sent to the guests this often, in seconds.
const SNAPSHOT_EVERY := 0.05
## A guest who's lost the host tries again this often, for this long, in seconds.
const RETRY_EVERY := 3.0
const RETRY_FOR := 60.0

signal changed

## The game this plays for: main, whose run and allies these are.
var game: Node
var hosting := false
var guesting := false
## A line on how it's going, for whoever's looking: who's here, or what went wrong.
var status := ""

## Host: each guest by peer id, as {info, sender, in_run}: what they said hello with, their own
## snapshot sender, and whether the run under way is theirs (told of it, and in it or choosing).
var guests := {}
var _since_snapshot := 0.0
var _events: Array[Dictionary] = []

## Guest: the host's world as it arrives, the snapshots not yet put into it (each with the last
## steering the host had acted on when it was taken), and which of its cats is theirs.
var receiver := Snapshot.Receiver.new()
var arrived: Array[Array] = []
var my_cat_id := 0
var summary := {}
## Guest: who they are to the host, kept for the session, so a dropped connection picks up the same
## cat; the host's address; and, lost from it in a run, finding it again.
var token := ""
var reconnecting := false
var _address := ""
var _retry_for := 0.0
var _retry_in := 0.0
var _parting_in := 0.0


func _ready() -> void:
	name = "Online"
	token = "%x%x" % [randi(), randi()]
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_host_gone)


func active() -> bool:
	return hosting or guesting


## Starts listening for guests. Returns false, with a status saying why, if it can't.
func host() -> bool:
	var peer := Session.host()
	if peer == null:
		status = "Couldn't listen for allies on port %d: is another game hosting?" % Session.PORT
		return false
	multiplayer.multiplayer_peer = peer
	hosting = true
	_host_status()
	return true


func join(address: String) -> bool:
	var peer := Session.join(address)
	if peer == null:
		status = "Couldn't set out for %s" % address
		return false
	multiplayer.multiplayer_peer = peer
	guesting = true
	_address = address
	status = "Finding the host at %s..." % address
	return true


## Guest: leaving the crew on purpose, said to the host first, so their cat goes at once rather
## than being kept for a connection that isn't coming back. Then gone, a moment later.
func part() -> void:
	if connected():
		parting.rpc_id(1)
		_parting_in = 0.2
		return
	leave()


func leave() -> void:
	_parting_in = 0.0
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	hosting = false
	guesting = false
	reconnecting = false
	guests.clear()
	receiver = Snapshot.Receiver.new()
	arrived.clear()
	my_cat_id = 0
	changed.emit()


func _host_status() -> void:
	var where := Session.addresses()
	var at := ("at %s" % where[0]) if not where.is_empty() else "on this machine"
	status = "Hosting %s: %d %s" % [at, guests.size(), "ally" if guests.size() == 1 else "allies"]


func _on_peer_connected(peer: int) -> void:
	if hosting:
		guests[peer] = {"info": {}, "sender": null, "in_run": false}
		Session.notice_drops(multiplayer.multiplayer_peer, peer)
		_host_status()


func _on_peer_disconnected(peer: int) -> void:
	if hosting and guests.has(peer):
		guests.erase(peer)
		game.ally_gone(peer)
		_host_status()
		changed.emit()


func _on_connected() -> void:
	Session.notice_drops(multiplayer.multiplayer_peer, 1)
	status = "With the host: waiting for them to go out to Endless"
	reconnecting = false
	var info: Dictionary = game.what_i_bring()
	info.token = token
	hello.rpc_id(1, info)
	changed.emit()


func _on_failed() -> void:
	# Finding the host again, a try that failed is only one try.
	if reconnecting:
		return
	leave()
	status = "Couldn't reach the host"
	changed.emit()


## The host gone. In a run, that may only be the connection: it's tried again for a minute, the
## world held still, before the guest gives up on it.
func _on_host_gone() -> void:
	if guesting and game.guest_in_run():
		reconnecting = true
		_retry_for = RETRY_FOR
		_retry_in = RETRY_EVERY
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
		status = "Lost the host: finding them again..."
		changed.emit()
		return
	leave()
	status = "The host has gone"
	changed.emit()


func _process(delta: float) -> void:
	if _parting_in > 0.0:
		_parting_in -= delta
		if _parting_in <= 0.0:
			leave()
		return
	if not reconnecting:
		return
	_retry_for -= delta
	_retry_in -= delta
	if _retry_for <= 0.0:
		leave()
		status = "Lost the host for good"
		game.guest_lost()
		changed.emit()
		return
	status = "Lost the host: finding them again (%d s)" % ceili(_retry_for)
	if _retry_in > 0.0:
		return
	_retry_in = RETRY_EVERY
	var peer := Session.join(_address)
	if peer != null:
		multiplayer.multiplayer_peer = peer


## Host: a run out to Endless is starting. Every guest is told, and chooses.
func run_begins(setup: Dictionary) -> void:
	for peer: int in guests:
		_tell_of_run(peer, setup)


func _tell_of_run(peer: int, setup: Dictionary) -> void:
	var guest: Dictionary = guests[peer]
	guest.in_run = true
	guest.chosen = false
	guest.sender = Snapshot.Sender.new()
	told_of_run.rpc_id(peer, setup)


## Host: whether any guest told of the run hasn't chosen yet.
func waiting_on_guests() -> bool:
	return guests.values().any(func(guest: Dictionary) -> bool: return guest.in_run and not guest.get("chosen", false))


## Host: each step's events, gathered for the next snapshot; and every frame, the snapshots out.
func host_frame(delta: float, arena: Arena, events: Array[Dictionary]) -> void:
	_events.append_array(events)
	_since_snapshot += delta
	if _since_snapshot < SNAPSHOT_EVERY:
		return
	_since_snapshot = 0.0
	var world := Snapshot.take(arena, _events)
	_events.clear()
	for peer: int in guests:
		var guest: Dictionary = guests[peer]
		if guest.in_run and guest.sender != null:
			snapshot.rpc_id(peer, (guest.sender as Snapshot.Sender).delta(world), game.ally_steered_to(peer))


## Host: the crew is down. Each guest in it is sent the run's numbers.
func run_over(numbers: Dictionary) -> void:
	for peer: int in guests:
		if guests[peer].in_run:
			guests[peer].in_run = false
			told_run_over.rpc_id(peer, numbers)


## Whether there's a host to talk to just now: not while it's being found again.
func connected() -> bool:
	return guesting and not reconnecting and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


## Guest: what they chose to start with, to the host.
func choose(weapon: String) -> void:
	if connected():
		chose.rpc_id(1, weapon)


## Guest: how they steer, every frame, numbered so the host can say which it's acted on; and what
## they press, as it's pressed.
func send_steering(steering: Vector2, number: int) -> void:
	if connected():
		steered.rpc_id(1, steering, number)


func send_press(action: String, index: int) -> void:
	if connected():
		pressed.rpc_id(1, action, index)


# What a guest says to the host.

@rpc("any_peer", "reliable")
func hello(info: Dictionary) -> void:
	var peer := multiplayer.get_remote_sender_id()
	if not hosting or not guests.has(peer):
		return
	guests[peer].info = info
	var setup: Dictionary = game.run_setup_for_guests()
	if setup.is_empty():
		told_no_run.rpc_id(peer)
		changed.emit()
		return
	# Back from a dropped connection: their own cat, as it was, with nothing to choose.
	var returning: int = game.ally_returns(peer, info.get("token", ""))
	_tell_of_run(peer, setup)
	if returning != 0:
		guests[peer].chosen = true
		told_your_cat.rpc_id(peer, returning)
	changed.emit()


@rpc("any_peer", "reliable")
func chose(weapon: String) -> void:
	var peer := multiplayer.get_remote_sender_id()
	if not hosting or not guests.has(peer) or not guests[peer].in_run or guests[peer].get("chosen", false):
		return
	var cat_id: int = game.ally_arrives(peer, guests[peer].info, weapon)
	if cat_id == 0:
		return
	guests[peer].chosen = true
	told_your_cat.rpc_id(peer, cat_id)


@rpc("any_peer", "reliable")
func parting() -> void:
	if hosting:
		game.ally_leaves(multiplayer.get_remote_sender_id())


@rpc("any_peer", "unreliable_ordered")
func steered(steering: Vector2, number: int) -> void:
	if hosting:
		game.ally_steers(multiplayer.get_remote_sender_id(), steering.limit_length(1.0), number)


@rpc("any_peer", "reliable")
func pressed(action: String, index: int) -> void:
	if hosting:
		game.ally_presses(multiplayer.get_remote_sender_id(), action, index)


# What the host says to a guest.

@rpc("authority", "reliable")
func told_of_run(setup: Dictionary) -> void:
	receiver = Snapshot.Receiver.new()
	arrived.clear()
	my_cat_id = 0
	game.guest_run_begins(setup)


## Nothing under way to join: wait for the next.
@rpc("authority", "reliable")
func told_no_run() -> void:
	game.guest_run_over({})


@rpc("authority", "reliable")
func told_your_cat(cat_id: int) -> void:
	my_cat_id = cat_id


@rpc("authority", "reliable")
func snapshot(packed: PackedByteArray, steered_to: int) -> void:
	arrived.append([packed, steered_to])


@rpc("authority", "reliable")
func told_run_over(numbers: Dictionary) -> void:
	summary = numbers
	status = "With the host: waiting for them to go out again"
	game.guest_run_over(numbers)
