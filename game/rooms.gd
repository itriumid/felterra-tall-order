class_name Rooms
extends Node
## Playing online by room code: the host asks the game's rooms service (rooms/, at
## api.tall-order.felterra.games.itrium.id) for a room, and is given a short code; a guest gives
## the code, and the service introduces the two, passing what each needs to reach the other
## straight. Then they talk directly, over WebRTC, and the service carries nothing of the game. Each machine finds its own address on the internet
## through Cloudflare's STUN server.
##
## The host keeps its line to the service open, so guests can join, or come back after a dropped
## connection, for as long as it's hosting. A guest's closes once they're through.

signal hosted(code: String)
signal joined
signal failed(reason: String)

const SERVICE := "wss://api.tall-order.felterra.games.itrium.id"
const ICE := {"iceServers": [{"urls": ["stun:stun.cloudflare.com:3478"]}]}
## Each code's letters: none that read as another (no I, L or O, no 0 or 1).
const LETTERS := "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
const CODE_LENGTH := 6
## Why the service turned a guest away, as a guest is told.
const REASONS := {
	"no_room": "No room with that code", "full": "That room is full", "host_gone": "The host has gone",
	"unreachable": "Couldn't reach the rooms service",
}

## The connection the game plays over, once the service has said who's who.
var peer := WebRTCMultiplayerPeer.new()
var code := ""
## Where the service is: the game's own, or a local one to try things out (--rooms=<address>).
var service := SERVICE
## The game's version, told to the service: a guest on another than the host's is turned away.
var version := ""
var _socket := WebSocketPeer.new()
var _id := 0
var _was_open := false
var _hosting := false


## Whether this build can play over WebRTC: without its extension (a build from source that
## hasn't fetched it), only by address.
static func available() -> bool:
	return WebRTCPeerConnection.new().initialize(ICE) == OK


## A code as typed, put right: capitals, and only its letters.
static func tidy(typed: String) -> String:
	var kept := ""
	for letter in typed.to_upper():
		if letter in LETTERS:
			kept += letter
	return kept


func host() -> void:
	_hosting = true
	_open(service + "/host?version=" + version.uri_encode())


func join(room: String) -> void:
	_hosting = false
	code = tidy(room)
	_open(service + "/join/" + code + "?version=" + version.uri_encode())


func close() -> void:
	_socket.close()
	peer.close()


func _open(url: String) -> void:
	_was_open = false
	if _socket.connect_to_url(url) != OK:
		failed.emit(REASONS.unreachable)


func _process(_delta: float) -> void:
	_socket.poll()
	var state := _socket.get_ready_state()
	# Read even once it's closed: turned away, the service says why and closes in one breath.
	while _socket.get_available_packet_count() > 0:
		_was_open = true
		var message: Variant = JSON.parse_string(_socket.get_packet().get_string_from_utf8())
		if message is Dictionary:
			_heard(message)
	if state == WebSocketPeer.STATE_OPEN:
		_was_open = true
	elif state == WebSocketPeer.STATE_CLOSED and not _was_open and _id == 0:
		# Turned away as it opened, the reason is in the close, the message lost: "full", or
		# "version:0.0.6". With no reason at all, it never got through to the service.
		_was_open = true
		var reason := _socket.get_close_reason()
		if reason.begins_with("version:"):
			failed.emit(Online.other_version(reason.trim_prefix("version:"), version))
		else:
			failed.emit(REASONS.get(reason, REASONS.unreachable))


func _heard(message: Dictionary) -> void:
	match message.get("type", ""):
		"room":
			code = message.code
			_id = 1
			peer.create_server()
			hosted.emit(code)
		"joined":
			_id = int(message.id)
			peer.create_client(_id)
			joined.emit()
			_reach(1)
		"peer":
			_reach(int(message.id))
		"peer_left":
			# Gone from the service before they got through: let go. One who's through has closed
			# their line to the service on purpose, and plays on over WebRTC.
			var id := int(message.id)
			if peer.has_peer(id) and not peer.get_peer(id).connected:
				peer.remove_peer(id)
		"offer", "answer":
			var from := int(message.from)
			if peer.has_peer(from):
				(peer.get_peer(from).connection as WebRTCPeerConnection).set_remote_description(message.type, message.sdp)
		"candidate":
			var from := int(message.from)
			if peer.has_peer(from):
				(peer.get_peer(from).connection as WebRTCPeerConnection).add_ice_candidate(message.mid, int(message.index), message.sdp)
		"error":
			if message.get("reason", "") == "version":
				failed.emit(Online.other_version(str(message.get("version", "")), version))
				return
			failed.emit(REASONS.get(message.get("reason", ""), "The rooms service said no"))


## A connection to another player, set up through the service: the guest, the newer of the two,
## makes the offer.
func _reach(id: int) -> void:
	var connection := WebRTCPeerConnection.new()
	connection.initialize(ICE)
	connection.session_description_created.connect(func(kind: String, sdp: String) -> void:
		connection.set_local_description(kind, sdp)
		_send({"type": kind, "to": id, "sdp": sdp}))
	connection.ice_candidate_created.connect(func(mid: String, index: int, sdp: String) -> void:
		_send({"type": "candidate", "to": id, "mid": mid, "index": index, "sdp": sdp}))
	peer.add_peer(connection, id)
	if id < _id:
		connection.create_offer()


func _send(message: Dictionary) -> void:
	if _socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_socket.send_text(JSON.stringify(message))


## A guest through to the host: the service has done its part.
func through() -> void:
	if not _hosting:
		_socket.close()
