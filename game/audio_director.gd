class_name AudioDirector
extends Node
## Plays the game's sounds from what the simulation does: a shot for each round fired, a whoosh
## for each swing, a thud for each hit (small for a rat, deep for a giant), a giant's footfalls in
## step with his stride. Sounds in the world sit where they happen and fade with distance; the
## interface's play flat. Voices are limited per sound, so a horde doesn't drown everything.

## Players for sounds in the world, and the most of any one sound playing at once.
const VOICES := 24
const LIMITS := {"squeak": 3, "hit_small": 6, "footstep_giant": 4, "swing": 4, "bite": 3}
const DEFAULT_LIMIT := 4
## Ground a giant covers between footfalls, in meters: half his stride.
const GIANT_STEP := 0.7

var arena: Arena
var _world: Node2D
var _voices: Array[AudioStreamPlayer2D] = []
var _interface: Array[AudioStreamPlayer] = []
var _seen := {}
## How many times each sound has played: what a test or a probe can check, since nobody can hear
## a headless run.
var played := {}


func setup(world: Node2D) -> void:
	_world = world
	for index in VOICES:
		var voice := AudioStreamPlayer2D.new()
		voice.bus = "Effects"
		voice.max_distance = 900.0
		voice.attenuation = 1.6
		_world.add_child(voice)
		_voices.append(voice)
	for index in 4:
		var player := AudioStreamPlayer.new()
		player.bus = "Interface"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_interface.append(player)


## A new run: forget what was counted in the last one.
func watch(new_arena: Arena) -> void:
	arena = new_arena
	_seen.clear()


## Hits from the simulation's steps since the last frame.
func take_events(events: Array[Dictionary]) -> void:
	for event in events:
		match event.by:
			"stomp": play_at("stomp", event.position, 0.0)
			"fall": play_at("fall", event.position, 2.0)
			"bite": play_at("bite", event.position, -6.0)
			_:
				if event.get("giant", false):
					play_at("hit_big", event.position, -3.0)
				else:
					play_at("hit_small", event.position, -6.0)
					if event.killed:
						play_at("squeak", event.position, -8.0)


## Watches the simulation's counters each frame: rounds fired, swings, dodges, hits taken, the
## crew's level, and how far each giant has walked.
func _process(_delta: float) -> void:
	if arena == null:
		return
	for cat in arena.cats:
		for weapon in cat.weapons:
			if _counted(weapon, "rounds", weapon.rounds_fired):
				play_at("shot_" + ("submachine_gun" if weapon.name == "submachine_gun" else "handgun"), cat.body.position, -4.0)
			if _counted(weapon, "swings", weapon.swings):
				# Deeper for a keris, quicker for a kerambit.
				var pitch: float = {"keris": 0.85, "kerambit": 1.25}.get(weapon.name, 1.0)
				play_at("swing", cat.body.position, -10.0, pitch)
		if _counted(cat, "dodges", 1 if cat.dodging_for > 0.0 else 0) and cat.dodging_for > 0.0:
			play_at("dodge", cat.body.position, -8.0)
		if _counted(cat, "hurt", cat.hits_taken):
			play_at("hurt", cat.body.position, -6.0)
	if _counted(arena, "level", arena.level) and arena.level > 1:
		interface("level_up")
	for giant in arena.giants:
		if not giant.standing():
			continue
		var walked: float = _seen.get([giant, "walked"], 0.0) + giant.body.velocity.length() * get_process_delta_time()
		if walked >= GIANT_STEP:
			walked -= GIANT_STEP
			play_at("footstep_giant", giant.body.position, -4.0)
		_seen[[giant, "walked"]] = walked


## Whether a counter has moved since the last look; the first look only takes note.
func _counted(thing: Object, what: String, value: int) -> bool:
	var key := [thing, what]
	var changed: bool = _seen.has(key) and _seen[key] != value
	_seen[key] = value
	return changed


## A sound in the world, at a point in meters, in one of its variants, a little off pitch each
## time so repeats don't ring the same.
func play_at(sound_name: String, where: Vector2, volume_db := 0.0, pitch := 1.0) -> void:
	var limit: int = LIMITS.get(sound_name, DEFAULT_LIMIT)
	var playing := 0
	var free: AudioStreamPlayer2D = null
	for voice in _voices:
		if voice.playing:
			if voice.get_meta("sound", "") == sound_name:
				playing += 1
		elif free == null:
			free = voice
	if playing >= limit or free == null:
		return
	free.stream = SoundKit.stream(sound_name, randi() % SoundKit.VARIANTS)
	free.set_meta("sound", sound_name)
	free.position = World.to_screen(where)
	free.volume_db = volume_db
	free.pitch_scale = pitch * randf_range(0.95, 1.05)
	free.play()
	played[sound_name] = played.get(sound_name, 0) + 1


## A sound of the interface: flat, not placed in the world.
func interface(sound_name: String) -> void:
	for player in _interface:
		if not player.playing:
			player.stream = SoundKit.stream(sound_name, 0)
			player.play()
			played[sound_name] = played.get(sound_name, 0) + 1
			return
