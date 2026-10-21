extends SceneTree
## Plays every path through the menus the way a player would, pressing the keys, and fails if any
## step doesn't land where it should or a script error is raised. Screenshots only show a page;
## this chooses from them. Run with:
## timeout 120 godot --headless --path . --script tools/check_menus.gd -- --title

## Each step: the action to press (or a note to act on), the page it should land on ("" while
## playing), and, for some, what else should hold after it: where she is, and where the reset of
## all progress stands.
const STEPS := [
	# Play, then the walk into the village: a line hurried along, then the whole scene skipped.
	["menu_choose", "", {"_place": "arriving"}], ["menu_choose", "", {"_place": "arriving"}],
	["pause", "", {"_place": "village"}],
	["pause", "village_pause"], ["menu_choose", "", {"_place": "village"}],
	# With salvage, cloth and cats to spare: restore the smithy and forge a vest; restore the
	# weaver's hut and buy a gray coat, and wear it.
	["grant", ""], ["to_smithy", ""], ["menu_choose", "", {"village.restored": ["smithy"]}],
	["menu_choose", "forge"], ["menu_choose", "forge", {"village.forged": ["gear:vest"]}], ["pause", ""],
	["to_weaver", ""], ["menu_choose", "", {"village.restored": ["smithy", "hut_0"]}],
	["menu_choose", "looks"], ["move_down", "looks"], ["menu_choose", "looks", {"village.coat": "gray"}], ["pause", ""],
	["to_home", ""],
	# Out along the path to the clearing, and a run.
	["leave_village", "", {"_place": "run"}], ["pick_1", ""],
	["pause", "pause"], ["menu_choose", ""],
	["pause", "pause"], ["move_down", "pause"], ["menu_choose", "settings"], ["move_down", "settings"],
	["move_right", "settings"], ["pause", "pause"], ["pause", ""],
	# Down, then straight back out.
	["down", "summary"], ["move_down", "summary"], ["menu_choose", "", {"_place": "run"}], ["pick_2", ""],
	# Down again, and home to the village; the walk home skipped.
	["down", "summary"], ["menu_choose", "", {"_place": "arriving"}], ["pause", "", {"_place": "village"}],
	# Out again, then giving the run up: back to the village from the pause menu.
	["leave_village", "", {"_place": "run"}], ["pick_1", ""],
	["pause", "pause"], ["move_down", "pause"], ["move_down", "pause"], ["move_down", "pause"],
	["menu_choose", "", {"_place": "arriving"}], ["pause", "", {"_place": "village"}],
	# From the village's pause menu, back to the title.
	["pause", "village_pause"], ["move_down", "village_pause"], ["move_down", "village_pause"],
	["menu_choose", "title", {"_place": "title"}], ["move_down", "title"], ["menu_choose", "settings"],
	# Up from the top wraps to Back, then up again to Reset all progress: asked, then done.
	["move_up", "settings"], ["move_up", "settings"], ["menu_choose", "settings", {"_reset_state": "asking"}],
	["menu_choose", "settings", {"_reset_state": "done"}],
	["pause", "title"],
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
		elif action == "leave_village":
			# Walked to the end of the path out.
			_main.village_map.cat.body.position = Vector2(VillageMap.SIZE.x - 0.1, VillageMap.RETURN_SPOT.y)
		elif action == "grant":
			_main.village.salvage = 200
			_main.village.cloth = 50
			for index in 6:
				_main.village.cats.append({"name": Cage.NAMES[index], "coat": "gray"})
		elif action in ["to_smithy", "to_weaver", "to_home"]:
			# Walked up to a door, or back into the open.
			var spots := {"to_smithy": VillageMap.SMITHY, "to_weaver": VillageMap.HUTS[0]}
			var footprint: Rect2 = spots.get(action, Rect2(VillageMap.HOME_SPOT, Vector2.ZERO))
			_main.village_map.cat.body.position = Vector2(footprint.get_center().x, footprint.end.y + 0.45) if action != "to_home" else VillageMap.HOME_SPOT
		else:
			Input.action_press(action)
	elif phase == 1 and InputMap.has_action(action):
		Input.action_release(action)
	elif phase == 5:
		var wanted: String = STEPS[_step][1]
		if _main._page != wanted:
			_failures.append("step %d (%s): on '%s', wanted '%s'" % [_step + 1, action, _main._page, wanted])
		if STEPS[_step].size() > 2:
			var expected: Dictionary = STEPS[_step][2]
			for property: String in expected:
				var found: Variant = _main
				for part in property.split("."):
					found = found.get(part)
				if found != expected[property]:
					_failures.append("step %d (%s): %s is '%s', wanted '%s'" % [_step + 1, action, property, found, expected[property]])
		_step += 1
	return false


func _finish() -> void:
	for failure in _failures:
		print("FAIL  ", failure)
	for error in _errors.errors:
		print("FAIL  error while playing the menus: ", error)
	print("%d of %d menu steps landed where they should, with %d errors." % [STEPS.size() - _failures.size(), STEPS.size(), _errors.errors.size()])
	quit(1 if not _failures.is_empty() or not _errors.errors.is_empty() else 0)
