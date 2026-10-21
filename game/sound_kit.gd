class_name SoundKit
extends RefCounted
## Every sound effect in the game, synthesized when the game starts: no recordings, nothing to
## license. Like the palette for the art, a few shared building blocks (a tone that sweeps,
## filtered noise, a pulse wave, the stepped noise of old sound chips) make every sound, so they
## all sound like one game. Each comes in a few variants, so a repeat never sounds the same.

const RATE := 22050
const VARIANTS := 3

## Every sound there is, by name. The director plays them by these names.
const NAMES: Array[String] = [
	"shot_handgun", "shot_submachine_gun", "swing", "hit_small", "squeak", "hit_big", "bark", "hit_dog", "yelp", "saw_rev", "saw_cut",
	"pounce", "riposte", "shot_drone", "meriam", "blast", "crack", "mine_drop",
	"footstep_giant", "stomp", "fall", "dodge", "hurt", "bite",
	"level_up", "card", "reroll", "banish", "menu_move", "menu_choose", "menu_back",
]

static var _cache := {}


## A variant of a sound, made the first time it's asked for.
static func stream(sound_name: String, variant: int) -> AudioStreamWAV:
	var key := "%s|%d" % [sound_name, variant]
	if not _cache.has(key):
		var random := RandomNumberGenerator.new()
		random.seed = hash(key)
		_cache[key] = _to_stream(_render(sound_name, random))
	return _cache[key]


static func _render(sound_name: String, random: RandomNumberGenerator) -> PackedFloat32Array:
	var wobble := random.randf_range(0.94, 1.06)
	match sound_name:
		"shot_handgun":
			# A crack of noise over a thump, crushed a little like an old sound chip.
			return _mix([_noise(0.16, 0.035, 3400.0 * wobble, random, 2), _sweep(0.16, 170.0 * wobble, 55.0, 0.05)], [0.8, 0.9])
		"shot_submachine_gun":
			return _mix([_noise(0.09, 0.02, 4200.0 * wobble, random, 2), _sweep(0.09, 220.0 * wobble, 80.0, 0.025)], [0.75, 0.6])
		"swing":
			return _whoosh(0.16, 900.0 * wobble, 2600.0 * wobble, random, 0.5)
		"hit_small":
			return _mix([_sweep(0.11, 260.0 * wobble, 95.0, 0.035), _noise(0.05, 0.008, 1800.0, random, 1)], [0.9, 0.5])
		"squeak":
			return _chirp(0.13, [1700.0 * wobble, 2600.0 * wobble, 1300.0 * wobble], 0.25)
		"bark":
			# Two sharp barks, falling in pitch.
			return _mix([_chirp(0.09, [720.0 * wobble, 430.0 * wobble], 0.4), _noise(0.09, 0.03, 1800.0, random, 2)], [0.8, 0.4]) + _mix([_chirp(0.11, [680.0 * wobble, 380.0 * wobble], 0.4), _noise(0.1, 0.03, 1600.0, random, 2)], [0.9, 0.4])
		"hit_dog":
			return _mix([_sweep(0.16, 190.0 * wobble, 70.0, 0.06), _noise(0.08, 0.015, 1200.0, random, 1)], [1.0, 0.5])
		"yelp":
			return _chirp(0.18, [900.0 * wobble, 1300.0 * wobble, 600.0 * wobble], 0.35)
		"saw_rev":
			# A two-stroke engine opening up: a buzz climbing in pitch.
			return _mix([_chirp(0.6, [70.0 * wobble, 140.0 * wobble, 190.0 * wobble], 0.5), _noise(0.6, 0.5, 900.0, random, 3)], [0.5, 0.35])
		"saw_cut":
			return _mix([_chirp(0.4, [200.0 * wobble, 185.0 * wobble, 150.0 * wobble], 0.45), _noise(0.4, 0.3, 3200.0, random, 2)], [0.55, 0.6])
		"hit_big":
			return _mix([_sweep(0.22, 120.0 * wobble, 42.0, 0.08), _noise(0.12, 0.03, 600.0, random, 1)], [1.0, 0.5])
		"footstep_giant":
			return _mix([_sweep(0.3, 75.0 * wobble, 34.0, 0.11), _noise(0.2, 0.05, 380.0, random, 1)], [1.0, 0.45])
		"stomp":
			return _mix([_sweep(0.9, 62.0 * wobble, 26.0, 0.3), _noise(0.9, 0.35, 320.0, random, 1), _noise(0.3, 0.06, 2400.0, random, 3)], [1.0, 0.7, 0.3])
		"fall":
			return _mix([_sweep(1.3, 55.0 * wobble, 22.0, 0.45), _noise(1.3, 0.55, 280.0, random, 1), _crackle(1.0, random)], [1.0, 0.75, 0.35])
		"dodge":
			return _whoosh(0.22, 500.0 * wobble, 1400.0 * wobble, random, 0.35)
		"shot_drone":
			# A small gun on a light frame: a thinner, higher crack.
			return _mix([_noise(0.1, 0.02, 5200.0 * wobble, random, 2), _sweep(0.08, 320.0 * wobble, 120.0, 0.03)], [0.7, 0.5])
		"meriam":
			# The bamboo cannon: a deep, hollow boom, the tube ringing under it.
			return _mix([_sweep(0.8, 95.0 * wobble, 34.0, 0.26), _noise(0.6, 0.2, 520.0, random, 1), _chirp(0.25, [180.0 * wobble, 150.0 * wobble], 0.5)], [1.0, 0.7, 0.25])
		"blast":
			return _mix([_sweep(0.8, 72.0 * wobble, 26.0, 0.28), _noise(0.8, 0.28, 900.0, random, 1), _crackle(0.6, random)], [1.0, 0.8, 0.4])
		"crack":
			# Bamboo splitting: a dry snap and splinters.
			return _mix([_noise(0.22, 0.03, 3600.0, random, 2), _crackle(0.3, random)], [0.8, 0.5])
		"mine_drop":
			return _chirp(0.07, [1500.0 * wobble, 1350.0 * wobble], 0.3)
		"pounce":
			# Paws coming down hard: a soft thump with a scuff of grit.
			return _mix([_sweep(0.14, 170.0 * wobble, 60.0, 0.05), _noise(0.1, 0.03, 1500.0, random, 2)], [0.9, 0.4])
		"riposte":
			# Steel on steel: a bright ring over a short scrape.
			return _mix([_chirp(0.3, [1760.0 * wobble, 1700.0 * wobble], 0.25), _noise(0.06, 0.015, 6000.0, random, 1)], [0.35, 0.6])
		"hurt":
			# Something like a cat's yowl: a pulse falling in pitch.
			return _chirp(0.26, [880.0 * wobble, 1050.0 * wobble, 420.0 * wobble], 0.35)
		"bite":
			return _noise(0.05, 0.01, 5000.0, random, 1)
		"level_up":
			return _arpeggio(["D5", "F#5", "A5", "D6"], 0.075, 0.5)
		"card":
			return _arpeggio(["A5", "D6"], 0.05, 0.25)
		"reroll":
			return _mix([_noise(0.2, 0.06, 2600.0, random, 4), _arpeggio(["E5", "A5"], 0.06, 0.25)], [0.5, 0.6])
		"banish":
			return _arpeggio(["A5", "E5", "A4"], 0.07, 0.25)
		"menu_move":
			return _arpeggio(["E6"], 0.03, 0.125)
		"menu_choose":
			return _arpeggio(["A5", "E6"], 0.04, 0.25)
		"menu_back":
			return _arpeggio(["E6", "A5"], 0.04, 0.25)
	return PackedFloat32Array()


## A tone gliding from one pitch to another as it fades: thumps, thuds and booms.
static func _sweep(seconds: float, from: float, to: float, decay: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	var phase := 0.0
	for index in samples.size():
		var time := float(index) / RATE
		phase += TAU * (to + (from - to) * exp(-time / (decay * 0.6))) / RATE
		samples[index] = sin(phase) * exp(-time / decay) * minf(time / 0.002, 1.0)
	return samples


## Noise through a one-pole low-pass filter, fading. Steps above 1 hold each value that many
## samples, the coarse grain of an old sound chip.
static func _noise(seconds: float, decay: float, cutoff: float, random: RandomNumberGenerator, steps: int) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	var smoothing := exp(-TAU * cutoff / RATE)
	var level := 0.0
	var held := 0.0
	for index in samples.size():
		if index % steps == 0:
			held = random.randf_range(-1.0, 1.0)
		level = (1.0 - smoothing) * held + smoothing * level
		var time := float(index) / RATE
		samples[index] = level * exp(-time / decay) * minf(time / 0.001, 1.0) * 2.0
	return samples


## Air moving: noise whose brightness rises and falls, loudest in the middle.
static func _whoosh(seconds: float, low: float, high: float, random: RandomNumberGenerator, gain: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	var level := 0.0
	for index in samples.size():
		var along := float(index) / samples.size()
		var cutoff := low + (high - low) * sin(along * PI)
		var smoothing := exp(-TAU * cutoff / RATE)
		level = (1.0 - smoothing) * random.randf_range(-1.0, 1.0) + smoothing * level
		samples[index] = level * sin(along * PI) * gain * 3.0
	return samples


## A pulse wave through a run of pitches, for squeaks and yowls.
static func _chirp(seconds: float, pitches: Array[float], width: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	var phase := 0.0
	for index in samples.size():
		var along := float(index) / samples.size() * (pitches.size() - 1)
		var part := mini(int(along), pitches.size() - 2)
		var pitch := lerpf(pitches[part], pitches[part + 1], along - part)
		phase = fmod(phase + pitch / RATE, 1.0)
		var time := float(index) / RATE
		samples[index] = (1.0 if phase < width else -1.0) * 0.5 * minf(time / 0.004, 1.0) * (1.0 - float(index) / samples.size())
	return samples


## Debris settling: sparse clicks thinning out.
static func _crackle(seconds: float, random: RandomNumberGenerator) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	for index in samples.size():
		var along := float(index) / samples.size()
		if random.randf() < 0.004 * (1.0 - along):
			for click in mini(40, samples.size() - index):
				samples[index + click] += random.randf_range(-1.0, 1.0) * exp(-click / 8.0)
	return samples


## Square-wave notes one after another, the chiptune voice of the interface.
static func _arpeggio(notes: Array[String], note_seconds: float, width: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	var per_note := int(note_seconds * RATE)
	samples.resize(per_note * notes.size() + per_note)
	for at in notes.size():
		var pitch := _pitch(notes[at])
		var phase := 0.0
		for index in per_note * 2:
			var target := at * per_note + index
			if target >= samples.size():
				break
			phase = fmod(phase + pitch / RATE, 1.0)
			samples[target] += (0.4 if phase < width else -0.4) * exp(-float(index) / (per_note * 0.6))
	return samples


static func _pitch(note_name: String) -> float:
	var steps := {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
	var octave := int(note_name.right(1))
	var semitones: int = steps[note_name.left(1)] + (1 if note_name.contains("#") else 0) + (octave - 4) * 12
	return 440.0 * pow(2.0, semitones / 12.0)


static func _mix(parts: Array[PackedFloat32Array], gains: Array[float]) -> PackedFloat32Array:
	var length := 0
	for part in parts:
		length = maxi(length, part.size())
	var samples := PackedFloat32Array()
	samples.resize(length)
	for at in parts.size():
		for index in parts[at].size():
			samples[index] += parts[at][index] * gains[at]
	return samples


## Into a stream Godot can play: softly limited so nothing clips, then 16-bit.
static func _to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for index in samples.size():
		data.encode_s16(index * 2, int(tanh(samples[index]) * 30000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav


## The loudest any sample of a sound reaches, 0 to 1. For the tests.
static func peak(sound_name: String) -> float:
	var wav := stream(sound_name, 0)
	var loudest := 0
	for index in range(0, wav.data.size(), 2):
		loudest = maxi(loudest, absi(wav.data.decode_s16(index)))
	return loudest / 32767.0
