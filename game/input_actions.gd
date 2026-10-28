class_name InputActions
extends RefCounted
## Every control, for keyboard and gamepad, registered in code so the bindings live in one
## readable place instead of serialized events in project.godot. The left hand never leaves
## movement.

const BINDINGS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"dodge": [KEY_SPACE],
	"change_gear": [KEY_G],
	"pause": [KEY_ESCAPE],
	"menu_choose": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE],
	"change_aim": [KEY_T],
	"toggle_blood": [KEY_B],
	"pick_1": [KEY_1],
	"pick_2": [KEY_2],
	"pick_3": [KEY_3],
	"reroll": [KEY_R],
	"banish": [KEY_X],
	"read_cards": [KEY_TAB],
	"show_kit": [KEY_I],
	"toggle_overlay": [KEY_F3],
	"toggle_fullscreen": [KEY_F11],
}

const GAMEPAD_BUTTONS := {
	"dodge": JOY_BUTTON_A,
	"change_gear": JOY_BUTTON_Y,
	"pause": JOY_BUTTON_START,
	"menu_choose": JOY_BUTTON_A,
	"change_aim": JOY_BUTTON_X,
	"pick_1": JOY_BUTTON_LEFT_SHOULDER,
	"pick_2": JOY_BUTTON_DPAD_UP,
	"pick_3": JOY_BUTTON_RIGHT_SHOULDER,
	"reroll": JOY_BUTTON_DPAD_DOWN,
	"banish": JOY_BUTTON_B,
	"read_cards": JOY_BUTTON_BACK,
	"show_kit": JOY_BUTTON_LEFT_STICK,
}


## The actions a player who joined on a gamepad of their own has, as "dodge:1" for player 1 (from
## 0): a fight's controls, and joining or leaving before it.
const PLAYER_ACTIONS: Array[String] = ["move_up", "move_down", "move_left", "move_right", "dodge", "change_gear", "pause", "pick_1", "pick_2", "pick_3", "reroll", "banish", "read_cards"]

## Playing together on one screen: each gamepad that has joined, by device, and the player it is.
## Player 0 keeps the keyboard and every gamepad that hasn't joined.
static var claimed := {}


static func register() -> void:
	for action: String in BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode: Key in BINDINGS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)
	_pads_for_player_zero()


## The name of an action for a player: their own copy of it, or for player 0, the shared one.
static func of(action: String, player: int) -> String:
	return action if player == 0 else "%s:%d" % [action, player]


## A gamepad joins as a player of its own: its buttons are that player's, and no longer player 0's.
static func claim(device: int, player: int) -> void:
	claimed[device] = player
	for action in PLAYER_ACTIONS:
		var own := of(action, player)
		if InputMap.has_action(own):
			InputMap.erase_action(own)
		InputMap.add_action(own, 0.2)
		for event in _pad_events(action, device):
			InputMap.action_add_event(own, event)
	_pads_for_player_zero()


## Every gamepad back to player 0, as before anyone joined.
static func release_all() -> void:
	for device: int in claimed:
		for action in PLAYER_ACTIONS:
			if InputMap.has_action(of(action, claimed[device])):
				InputMap.erase_action(of(action, claimed[device]))
	claimed.clear()
	_pads_for_player_zero()


## Player 0's gamepad buttons: from any gamepad while none has joined, and from each one that
## hasn't once one has. Called again when a gamepad is plugged in.
static func _pads_for_player_zero() -> void:
	for action: String in BINDINGS:
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				InputMap.action_erase_event(action, event)
	var devices: Array[int] = [-1]
	if not claimed.is_empty():
		devices.clear()
		for device in Input.get_connected_joypads():
			if not claimed.has(device):
				devices.append(device)
	for device in devices:
		for action: String in BINDINGS:
			for event in _pad_events(action, device):
				InputMap.action_add_event(action, event)


## An action's gamepad buttons and stick, on one device (or every device, as -1).
static func _pad_events(action: String, device: int) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	if GAMEPAD_BUTTONS.has(action):
		var button := InputEventJoypadButton.new()
		button.button_index = GAMEPAD_BUTTONS[action]
		button.device = device
		events.append(button)
	if action in ["move_left", "move_right", "move_up", "move_down"]:
		var stick := InputEventJoypadMotion.new()
		stick.axis = JOY_AXIS_LEFT_X if action in ["move_left", "move_right"] else JOY_AXIS_LEFT_Y
		stick.axis_value = -1.0 if action in ["move_left", "move_up"] else 1.0
		stick.device = device
		events.append(stick)
	return events
