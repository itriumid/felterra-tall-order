extends SceneTree
## Plays a game online from both sides at once: two copies of the game in one process, each with
## its own multiplayer, talking over a real connection on this machine. The host hosts and goes
## out to Endless; the guest joins, chooses, and plays their cat in the host's world; then the
## crew goes down. Fails if any step doesn't happen, or an error is raised. Run with:
## timeout 120 godot --headless --path . --script tools/check_online.gd -- --title

## Each step: what to do, then what has to hold before the next, within a few seconds.
const STEPS := [
	"host", "join", "hello_heard", "go_out", "told_of_run", "guest_chooses", "guest_cat_in", "host_chooses",
	"world_arrives", "guest_steers", "guest_moved",
	# The connection drops, and comes back: the same cat, as it was.
	"guest_drops", "guest_returns",
	# Leaving on purpose: the cat goes at once. Then someone new drops in to the run under way,
	# dealt the cards the crew's level-ups have handed out.
	"guest_parts", "guest_gone", "guest_drops_in", "guest_chooses_late",
	"crew_down", "guest_summary",
]
const STEP_TIME := 6.0

class ErrorCounter extends Logger:
	var errors: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d in %s: %s" % [file, line, function, rationale if not rationale.is_empty() else code])


var _host: Node
var _guest: Node
var _errors := ErrorCounter.new()
var _step := 0
var _done := false
var _waited := 0.0
var _frames := 0
var _guest_started_at := Vector2.ZERO
var _guest_salvage := 0
var _dropped_cat := 0


func _init() -> void:
	OS.add_logger(_errors)


## A copy of the game under its own root, with its own multiplayer.
func _game(called: String) -> Node:
	var holder := Node.new()
	holder.name = called
	root.add_child(holder)
	set_multiplayer(SceneMultiplayer.new(), holder.get_path())
	var game: Node = load("res://game/main.tscn").instantiate()
	holder.add_child(game)
	return game


func _process(delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_host = _game("Host")
		_guest = _game("Guest")
	if _frames < 10:
		return false
	if _step >= STEPS.size():
		_finish(true)
		return true
	var step: String = STEPS[_step]
	if not _done:
		_do(step)
		_done = true
		_waited = 0.0
	_waited += delta
	if _holds(step):
		print("[online] ", step)
		_step += 1
		_done = false
	elif _waited > STEP_TIME:
		print("FAIL  step %d (%s) didn't happen in %.0f seconds" % [_step + 1, step, STEP_TIME])
		_finish(false)
		return true
	return false


func _do(step: String) -> void:
	match step:
		"host":
			_host._online.host()
		"join":
			_guest._online.join("127.0.0.1")
		"go_out":
			# Out to Endless as the board would send him, walked in already.
			_host._close_page()
			_host._start_run("endless")
			_host._entering = false
			_host._overlay.cutscene = false
		"guest_chooses":
			_guest._start_weapon = "nunchaku"
			_guest._online.choose("nunchaku")
		"host_chooses":
			_host._start_weapon = "handgun"
			_host._dress()
		"guest_steers":
			_guest_salvage = _guest.village.salvage
			_guest_started_at = _host_side_guest_cat().body.position
			_guest._online.send_steering(Vector2.RIGHT, _frames)
		"crew_down":
			_host.arena.salvage = 5
			_host.arena.lost = true
			for cat: Cat in _host.arena.cats:
				cat.health = 0.0
		"guest_drops":
			_dropped_cat = _guest._online.my_cat_id
			_guest._online.multiplayer.multiplayer_peer.close()
			_guest._online._on_host_gone()
		"guest_parts":
			# As "Leave the crew" does: gone, and back on the title.
			_guest._online.part()
			_guest._close_page()
			_guest._show_title()
		"guest_drops_in":
			_host.arena.level = 4
			_guest._online.token = "someone new"
			_guest._online.join("127.0.0.1")
		"guest_chooses_late":
			_guest._start_weapon = "handgun"
			_guest._online.choose("handgun")


func _holds(step: String) -> bool:
	match step:
		"host":
			return _host._online.hosting
		"join":
			return _guest._online.guesting
		"hello_heard":
			return _host._online.guests.size() == 1 and not _host._online.guests.values()[0].info.is_empty()
		"go_out":
			return _host._place == "run" and _host._run_kind == "endless"
		"told_of_run":
			return _guest._place == "run" and _host._online.waiting_on_guests()
		"guest_cat_in":
			return _host.arena.cats.size() == 2 and _guest._online.my_cat_id != 0
		"host_chooses":
			return not _host._choosing() and _host.arena.time > 0.5
		"world_arrives":
			var mine: Cat = _guest._online.receiver.objects.get(_guest._online.my_cat_id)
			return mine != null and _guest.cat == mine and _guest.arena.cats.size() == 2 \
				and _guest.arena.creatures.size() > 0 and _guest.arena.creatures.size() >= _host.arena.creatures.size() - 10 \
				and mine.weapons.size() > 0 and mine.weapons[0].name == "nunchaku"
		"guest_chooses", "guest_steers":
			return true
		"guest_moved":
			# Held right on the guest's side, their cat walks right on the host's.
			_guest._online.send_steering(Vector2.RIGHT, _frames)
			return _host_side_guest_cat().body.position.x > _guest_started_at.x + 0.5
		"crew_down":
			return _host._page == "summary"
		"guest_summary":
			# The crew's salvage home to the guest's village too, and the run in their crew record.
			return _guest._page == "guest_summary" and _guest._overlay.summary.get("crew", false) \
				and _guest.village.salvage == _guest_salvage + 5 and _guest.records.crew.time > 0.0
		"guest_drops":
			return _guest._online.reconnecting and not _host._allies.is_empty() and _host._allies[0].get("away", false) \
				and not _host._allies[0].cat in _host.arena.cats
		"guest_returns":
			var back: Dictionary = _host._allies[0] if not _host._allies.is_empty() else {}
			return not _guest._online.reconnecting and _guest._online.my_cat_id == _dropped_cat \
				and not back.is_empty() and not back.get("away", true) and back.cat in _host.arena.cats \
				and _guest.cat == _guest._online.receiver.objects.get(_dropped_cat)
		"guest_parts":
			return not _guest._online.guesting
		"guest_gone":
			return _host._online.guests.is_empty() and _host._allies.is_empty() and _host.arena.cats.size() == 1
		"guest_drops_in":
			return _guest._place == "run" and _guest._online.guesting
		"guest_chooses_late":
			if _host._allies.is_empty():
				return false
			var late: Cat = _host._allies[0].cat
			return late in _host.arena.cats and late.get_instance_id() != _dropped_cat and late.offers.size() >= 3 \
				and _guest.cat == _guest._online.receiver.objects.get(late.get_instance_id())
	return false


func _host_side_guest_cat() -> Cat:
	return _host._allies[0].cat


func _finish(passed: bool) -> void:
	for error in _errors.errors:
		print("FAIL  error while playing online: ", error)
	print("%d of %d steps online happened, with %d errors." % [_step, STEPS.size(), _errors.errors.size()])
	_host._online.leave()
	_guest._online.leave()
	quit(0 if passed and _errors.errors.is_empty() else 1)
