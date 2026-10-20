extends Node
## The prototype: one cat in a clearing, a horde coming out of the jungle, and the light under
## the canopy. It tests what's hardest about the game before anything else is built on it.
##
## Development aids: --horde=<count> starts with that many in the clearing; --no-spawn stops more
## coming; --at=<x>,<y> starts the cat there, in meters; --gear=<0 to 2> picks the gear; --sturdy keeps the cat alive; --screenshot=<path> saves
## --giant=<count> starts with giants close by, --giant-from=<x>,<y> that far from her; --start=<knife or handgun> skips choosing; --no-blood starts with blood off; --screenshot=<path> saves
## a frame after --screenshot-after seconds (default 4) and quits; --frames=<count> saves that
## many, a twentieth of a second apart, as <path>_1.png and on; --walk=<x>,<y> steers the cat
## that way on her own; --fallen=<count> scatters that many bodies.

## Sun through the canopy's gaps: where it reaches the ground, in meters.
const SHAFTS: Array[Vector2] = [
	Vector2(8.0, 6.0), Vector2(19.0, 10.0), Vector2(30.0, 7.0), Vector2(13.0, 17.0), Vector2(27.0, 18.0),
]
## Gear to try on with G, until upgrades hand it out: the start, then upgraded sets. An empty
## weapon list keeps whatever she started with.
const OUTFITS: Array[Dictionary] = [
	{"weapons": []},
	{"body": "vest", "head": "hard_hat", "neck": "bell_collar", "eyes": "goggles", "paws": "gloves", "feet": "boots", "waist": "jamu_flask", "weapons": []},
	{"body": "vest", "head": "caping", "neck": "scarf", "weapons": ["knife", "submachine_gun"]},
]
## The pause menu. Solo, it stops the world; online, it opens over a world that keeps running.
const MENU: Array[String] = ["carry_on", "settings", "start_again", "leave"]
## The settings page: each row's section, setting and name, by section.
const SETTING_ROWS: Array[Array] = [
	["graphics", "full_screen", "Full screen"], ["graphics", "window_scale", "Window size"],
	["graphics", "vsync", "Vertical sync"],
	["audio", "master", "Volume"], ["audio", "music", "Music"], ["audio", "effects", "Effects"],
	["audio", "interface", "Interface"],
	["gameplay", "aim", "Aim"], ["gameplay", "blood", "Blood"],
	["", "back", "Back"],
]
## There's no online play yet; when there is, the menu won't stop the world there.
const ONLINE := false

var arena: Arena
var cat: Cat
var _world: Node2D
var _camera: Camera2D
var _overlay: Overlay
var _muzzle_light: PointLight2D
var _entities: EntitiesView
var _ground: GroundView
var _outfit := 0
## The weapon she starts with, once chosen: until then the run waits.
var _start_weapon := ""
var _menu_open := false
## Which page of the menu is showing, and the row chosen on the settings page.
var _menu_page := "pause"
var _setting_choice := 0
var settings := Settings.new()
## Settings are read and written only in a real session: a development flag never touches them.
var _keeping_settings := false
var _open_settings_first := false
var _menu_after := -1.0
## For screenshots: show the cards' explanations as if Tab were held.
var _always_reading := false
var _menu_choice := 0
var _start := Arena.SIZE / 2.0
var _fallen := 0
var _giants := 0
var _giant_from := Vector2(3.5, -1.0)
var _walk := Vector2.ZERO
var _frames := 1
var _frames_saved := 0
var _sturdy := false
var _behind := 0.0
var _screenshot_path := ""
var _screenshot_after := 4.0


func _ready() -> void:
	InputActions.register()
	var horde := 0
	var spawning := true
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--horde="):
			horde = argument.trim_prefix("--horde=").to_int()
		elif argument.begins_with("--at="):
			var parts := argument.trim_prefix("--at=").split(",")
			_start = Vector2(parts[0].to_float(), parts[1].to_float())
		elif argument.begins_with("--fallen="):
			_fallen = argument.trim_prefix("--fallen=").to_int()
		elif argument.begins_with("--walk="):
			var parts := argument.trim_prefix("--walk=").split(",")
			_walk = Vector2(parts[0].to_float(), parts[1].to_float())
		elif argument.begins_with("--frames="):
			_frames = argument.trim_prefix("--frames=").to_int()
		elif argument.begins_with("--giant-from="):
			var parts := argument.trim_prefix("--giant-from=").split(",")
			_giant_from = Vector2(parts[0].to_float(), parts[1].to_float())
		elif argument.begins_with("--giant="):
			_giants = argument.trim_prefix("--giant=").to_int()
		elif argument == "--no-spawn":
			spawning = false
		elif argument.begins_with("--gear="):
			_outfit = clampi(argument.trim_prefix("--gear=").to_int(), 0, OUTFITS.size() - 1)
		elif argument.begins_with("--start="):
			_start_weapon = argument.trim_prefix("--start=")
		elif argument == "--no-blood":
			settings.set_value("gameplay", "blood", false)
		elif argument == "--reading":
			_always_reading = true
		elif argument == "--menu":
			_menu_open = true
		elif argument == "--settings":
			_open_settings_first = true
		elif argument.begins_with("--menu-after="):
			_menu_after = argument.trim_prefix("--menu-after=").to_float()
		elif argument == "--sturdy":
			_sturdy = true
		elif argument.begins_with("--screenshot="):
			_screenshot_path = argument.trim_prefix("--screenshot=")
		elif argument.begins_with("--screenshot-after="):
			_screenshot_after = argument.trim_prefix("--screenshot-after=").to_float()
	# A screenshot can't wait for someone to choose, unless it's of the choice itself.
	if not _screenshot_path.is_empty() and _start_weapon.is_empty() and not "--choose" in OS.get_cmdline_user_args():
		_start_weapon = "handgun"
	_keeping_settings = OS.get_cmdline_user_args().is_empty()
	if _keeping_settings:
		settings.load_from()
	settings.apply()
	_build_scene()
	_entities.blood = settings.get_value("gameplay", "blood")
	_begin(horde, spawning)
	if _menu_open or _open_settings_first:
		_open_menu()
		if _open_settings_first:
			_menu_page = "settings"


func _build_scene() -> void:
	# The menu and the interface keep running when the world is paused; the world doesn't.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_world = Node2D.new()
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world)
	# The forest floor under the canopy is dim; the sun only reaches it in shafts.
	var shade := CanvasModulate.new()
	shade.color = Color(0.62, 0.68, 0.62)
	_world.add_child(shade)
	_ground = GroundView.new()
	_world.add_child(_ground)
	_entities = EntitiesView.new()
	_world.add_child(_entities)
	var canopy := CanopyView.new()
	_world.add_child(canopy)
	var shaft_texture := _soft_light(Vector2i(220, 120))
	for spot in SHAFTS:
		var shaft := PointLight2D.new()
		shaft.texture = shaft_texture
		shaft.position = spot * World.PIXELS_PER_METER
		# Slanting in from the top left.
		shaft.rotation = deg_to_rad(-30.0)
		shaft.color = Palette.BRASS_LIGHT
		shaft.energy = 0.7
		shaft.height = 60.0
		_world.add_child(shaft)
	_muzzle_light = PointLight2D.new()
	_muzzle_light.texture = _soft_light(Vector2i(96, 96))
	_muzzle_light.color = Palette.SPARK
	_muzzle_light.height = 12.0
	_muzzle_light.energy = 0.0
	_world.add_child(_muzzle_light)
	_camera = Camera2D.new()
	_world.add_child(_camera)
	var interface := CanvasLayer.new()
	interface.layer = 10
	add_child(interface)
	_overlay = Overlay.new()
	interface.add_child(_overlay)


func _begin(horde: int, spawning: bool) -> void:
	arena = Arena.new()
	arena.spawning = spawning
	cat = arena.add_cat(_start)
	cat.aim_mode = settings.get_value("gameplay", "aim")
	_dress()
	if _sturdy:
		cat.health = 1.0e9
	for index in horde:
		arena.add_creature(arena.edge_point() * 0.7 + Arena.SIZE * 0.15)
	for index in _giants:
		arena.add_giant(_start + _giant_from + Vector2(index, index))
	for index in _fallen:
		var body := Body.new()
		body.radius = 0.08
		body.position = _start + Vector2(arena.random.randf_range(-7.0, 7.0), arena.random.randf_range(-4.0, 4.0))
		arena.fallen.append(body)
	_entities.arena = arena
	_ground.arena = arena
	_overlay.arena = arena
	_overlay.cat = cat


## Puts the outfit on her, with the weapon she chose to start with unless the outfit names its
## own.
func _dress() -> void:
	var outfit: Dictionary = OUTFITS[_outfit].duplicate()
	if (outfit.weapons as Array).is_empty():
		outfit.weapons = [_start_weapon if not _start_weapon.is_empty() else "handgun"]
	cat.wear(outfit)


## A soft pool of light: the one smooth thing on screen.
func _soft_light(size: Vector2i) -> GradientTexture2D:
	var texture := GradientTexture2D.new()
	texture.width = size.x
	texture.height = size.y
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	texture.gradient = gradient
	return texture


func _process(delta: float) -> void:
	if _menu_open:
		_read_menu()
		_take_screenshot(delta)
		return
	_read_controls()
	if _menu_after >= 0.0 and arena.time >= _menu_after:
		_menu_after = -1.0
		_open_menu()
	_overlay.choosing = _start_weapon.is_empty()
	if _start_weapon.is_empty():
		_camera.position = World.to_screen(cat.body.position)
		_take_screenshot(delta)
		return
	_behind = minf(_behind + delta, Arena.STEP * 5.0)
	var started := Time.get_ticks_usec()
	var steps := 0
	while _behind >= Arena.STEP:
		_behind -= Arena.STEP
		arena.step()
		steps += 1
	if steps > 0:
		_overlay.step_milliseconds = (Time.get_ticks_usec() - started) / 1000.0 / steps
	# On her spot on the ground, not her height: a hop or a throw moves her in the frame.
	_camera.position = World.to_screen(cat.body.position)
	_muzzle_light.position = World.to_screen(cat.body.position, Cat.GUN_HEIGHT) + cat.aim * 10.0
	_muzzle_light.energy = 1.6 * _entities.flash.get(cat, 0.0)
	_take_screenshot(delta)


func _take_screenshot(delta: float) -> void:
	if _screenshot_path.is_empty():
		return
	_screenshot_after -= delta
	if _screenshot_after <= 0.0:
		if _frames_saved == 0:
			print("%d frames a second, %.2f ms a step, %d in the horde" % [
				Engine.get_frames_per_second(), _overlay.step_milliseconds, arena.creatures.size()])
		_frames_saved += 1
		var path := _screenshot_path if _frames == 1 else _screenshot_path.replace(".png", "_%d.png" % _frames_saved)
		get_viewport().get_texture().get_image().save_png(path)
		_screenshot_after = 0.05
		if _frames_saved >= _frames:
			get_tree().quit()


func _open_menu() -> void:
	_menu_open = true
	_menu_page = "pause"
	_menu_choice = 0 if cat.alive() else MENU.find("start_again")
	if not ONLINE:
		get_tree().paused = true


func _close_menu() -> void:
	_menu_open = false
	_overlay.menu = []
	_overlay.setting_rows = []
	get_tree().paused = false


func _read_menu() -> void:
	if _menu_page == "settings":
		_read_settings()
	else:
		_read_pause()
	_overlay.menu = _menu_lines()
	_overlay.menu_choice = _menu_choice
	_overlay.setting_rows = _setting_lines() if _menu_page == "settings" else []
	_overlay.setting_choice = _setting_choice


func _read_pause() -> void:
	if Input.is_action_just_pressed("pause") and cat.alive():
		_close_menu()
		return
	if Input.is_action_just_pressed("move_up"):
		_menu_choice = wrapi(_menu_choice - 1, 0, MENU.size())
	if Input.is_action_just_pressed("move_down"):
		_menu_choice = wrapi(_menu_choice + 1, 0, MENU.size())
	if Input.is_action_just_pressed("menu_choose"):
		match MENU[_menu_choice]:
			"carry_on":
				if cat.alive():
					_close_menu()
			"settings":
				_menu_page = "settings"
				_setting_choice = 0
			"start_again":
				_close_menu()
				_start_weapon = ""
				_outfit = 0
				_begin(0, true)
			"leave":
				get_tree().quit()


## The settings page: up and down choose a row, left and right change it, Escape goes back.
func _read_settings() -> void:
	if Input.is_action_just_pressed("pause"):
		_menu_page = "pause"
		return
	if Input.is_action_just_pressed("move_up"):
		_setting_choice = wrapi(_setting_choice - 1, 0, SETTING_ROWS.size())
	if Input.is_action_just_pressed("move_down"):
		_setting_choice = wrapi(_setting_choice + 1, 0, SETTING_ROWS.size())
	var row: Array = SETTING_ROWS[_setting_choice]
	var direction := 0
	if Input.is_action_just_pressed("move_left"):
		direction = -1
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("menu_choose"):
		direction = 1
	if direction == 0:
		return
	if row[1] == "back":
		if Input.is_action_just_pressed("menu_choose"):
			_menu_page = "pause"
		return
	settings.step(row[0], row[1], direction)
	_settings_changed()


## Puts changed settings into effect, in the run too, and keeps them.
func _settings_changed() -> void:
	settings.apply()
	cat.aim_mode = settings.get_value("gameplay", "aim")
	_entities.blood = settings.get_value("gameplay", "blood")
	if _keeping_settings:
		settings.save()


func _menu_lines() -> Array[String]:
	var lines: Array[String] = []
	for item in MENU:
		match item:
			"carry_on": lines.append("Carry on" if cat.alive() else "Carry on (she's down)")
			"settings": lines.append("Settings")
			"start_again": lines.append("Start again")
			"leave": lines.append("Leave the game")
	return lines


## Each settings row as the page shows it: {section, name, value, volume}. A volume shows as a
## bar; the rest as words.
func _setting_lines() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row: Array in SETTING_ROWS:
		var line := {"section": row[0], "name": row[2], "value": "", "volume": -1}
		if row[1] != "back":
			var value: Variant = settings.get_value(row[0], row[1])
			match row[1]:
				"window_scale": line.value = "%d by %d" % [640 * int(value), 360 * int(value)]
				"aim": line.value = {"nearest": "Nearest", "toughest": "Toughest first", "crowd": "Thickest crowd"}[value]
				"blood": line.value = "On" if value else "Off: dust and fur instead"
				_:
					if value is bool:
						line.value = "On" if value else "Off"
					else:
						line.volume = int(value)
		rows.append(line)
	return rows


func _read_controls() -> void:
	if _start_weapon.is_empty():
		if Input.is_action_just_pressed("pick_1"):
			_start_weapon = "knife"
		elif Input.is_action_just_pressed("pick_2"):
			_start_weapon = "handgun"
		if not _start_weapon.is_empty():
			_dress()
		return
	cat.steering = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _walk != Vector2.ZERO:
		cat.steering = _walk
	if Input.is_action_just_pressed("dodge"):
		cat.dodge()
	if Input.is_action_just_pressed("change_gear"):
		_outfit = (_outfit + 1) % OUTFITS.size()
		_dress()
	# Cards: 1, 2 and 3 play a choice from the oldest offer; with X held, they banish it instead.
	for index in 3:
		if Input.is_action_just_pressed("pick_%d" % (index + 1)):
			if Input.is_action_pressed("banish"):
				cat.banish(index, arena.random)
			else:
				cat.play(index)
	if Input.is_action_just_pressed("reroll"):
		cat.reroll(arena.random)
	_overlay.reading = Input.is_action_pressed("read_cards") or _always_reading
	_overlay.banishing = Input.is_action_pressed("banish")
	# Shortcuts for settings: they change the saved settings, as the menu would.
	if Input.is_action_just_pressed("change_aim"):
		settings.step("gameplay", "aim", 1)
		_settings_changed()
	if Input.is_action_just_pressed("toggle_blood"):
		settings.step("gameplay", "blood", 1)
		_settings_changed()
	if Input.is_action_just_pressed("toggle_overlay"):
		_overlay.show_numbers = not _overlay.show_numbers
	if Input.is_action_just_pressed("toggle_fullscreen"):
		settings.step("graphics", "full_screen", 1)
		_settings_changed()
	# Escape opens the menu; when she's down, it opens on its own, ready to start again.
	if Input.is_action_just_pressed("pause") or not cat.alive():
		_open_menu()
