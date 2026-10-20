extends SceneTree
## Plays every path through the menus the way a player would, pressing the keys, and fails if any
## step doesn't land where it should or a script error is raised. Screenshots only show a page;
## this chooses from them. Run with:
## timeout 120 godot --headless --path . --script tools/check_menus.gd -- --title

## Each step: the action to press (or a note to act on), and the page it should land on ("" while
## playing).
const STEPS := [
	["menu_choose", ""], ["pick_1", ""],
	["pause", "pause"], ["menu_choose", ""],
	["pause", "pause"], ["move_down", "pause"], ["menu_choose", "settings"], ["move_down", "settings"],
	["move_right", "settings"], ["pause", "pause"], ["pause", ""],
	["down", "summary"], ["menu_choose", ""], ["pick_2", ""],
	["pause", "pause"], ["move_down", "pause"], ["move_down", "pause"], ["move_down", "pause"],
	["menu_choose", "title"], ["move_down", "title"], ["menu_choose", "settings"], ["pause", "title"],
]

## Hears every error the engine reports while the menus are played, script errors among them: an
## error can strike after a step has already landed on the right page.
class ErrorCounter extends Logger:
	var errors: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d in %s: %s" % [file, line, function, rationale if not rationale.is_empty() else code])


var _main: Node
var _errors := ErrorCounter.new()
var _frame := 0
var _step := 0
var _failures: Array[String] = []


func _init() -> void:
	OS.add_logger(_errors)
	_main = load("res://game/main.tscn").instantiate()
	root.add_child(_main)


func _process(_delta: float) -> bool:
	_frame += 1
	# A key goes down for a frame, then the game gets a few frames to act on it.
	var phase := _frame % 6
	if _frame < 12:
		return false
	if _step >= STEPS.size():
		_finish()
		return true
	var action: String = STEPS[_step][0]
	if phase == 0:
		if action == "down":
			_main.cat.health = 0.0
		else:
			Input.action_press(action)
	elif phase == 1 and action != "down":
		Input.action_release(action)
	elif phase == 5:
		var wanted: String = STEPS[_step][1]
		if _main._page != wanted:
			_failures.append("step %d (%s): on '%s', wanted '%s'" % [_step + 1, action, _main._page, wanted])
		_step += 1
	return false


func _finish() -> void:
	for failure in _failures:
		print("FAIL  ", failure)
	for error in _errors.errors:
		print("FAIL  error while playing the menus: ", error)
	print("%d of %d menu steps landed where they should, with %d errors." % [STEPS.size() - _failures.size(), STEPS.size(), _errors.errors.size()])
	quit(1 if not _failures.is_empty() or not _errors.errors.is_empty() else 0)
