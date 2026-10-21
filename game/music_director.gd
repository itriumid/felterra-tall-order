class_name MusicDirector
extends Node
## Plays the soundtrack's layers together, in step, and fades each to what the run calls for:
## drums and bass always; chords, then the lead, as the horde thickens around her; the gamelan
## answering throughout; the rock layer whenever a giant is on his feet. In the pause menu it all
## drops back. Real music replaces the layers one for one; this stays.

## How far around her the horde counts toward the music, in meters, and how fast layers fade.
const NEAR := 6.0
const FADE := 1.5
const PAUSED_SHARE := 0.35

var arena: Arena
var cat: Cat
var _players := {}
var _levels := {}


func setup() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layers := MusicKit.make_all()
	for layer: String in layers:
		var player := AudioStreamPlayer.new()
		player.stream = layers[layer]
		player.bus = "Music"
		player.volume_db = -80.0
		add_child(player)
		_players[layer] = player
		_levels[layer] = 0.0
	# All together, so every layer keeps the same beat.
	for layer: String in _players:
		_players[layer].play()


## How loud each layer should be, 0 to 1, from how thick the horde is around her, whether a giant
## is standing, and whether the game is paused.
static func targets(horde_near: int, giant_standing: bool, paused: bool) -> Dictionary:
	var levels := {
		"drums": 1.0, "bass": 1.0,
		"chords": clampf(horde_near / 15.0, 0.0, 1.0),
		"lead": clampf((horde_near - 8) / 20.0, 0.0, 1.0),
		"gamelan": 0.75,
		"rock": 1.0 if giant_standing else 0.0,
	}
	if paused:
		for layer: String in levels:
			levels[layer] *= PAUSED_SHARE
	return levels


func _process(delta: float) -> void:
	if _players.is_empty() or arena == null:
		return
	# Behind the title there's no cat: the horde around her counts as none.
	var near := 0
	if cat != null:
		for creature in arena.creatures:
			if creature.body.position.distance_to(cat.body.position) < NEAR:
				near += 1
	# A machine at work counts as a giant: the rock comes in for it too.
	var giant := arena.giants.any(func(each: Giant) -> bool: return each.standing()) \
			or arena.machines.any(func(each: Machine) -> bool: return each.standing())
	var wanted := targets(near, giant, get_tree().paused)
	for layer: String in _players:
		_levels[layer] = move_toward(_levels[layer], wanted[layer], delta * FADE)
		_players[layer].volume_db = linear_to_db(maxf(_levels[layer], 0.0001))
