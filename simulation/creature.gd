class_name Creature
extends RefCounted
## One of the horde: a rat from the company's supply crates, or one of its guard dogs. Runs at the
## nearest cat and bites. A dog that gets close crouches (the warning), then lunges: a real leap
## through the air, which a dodge can get out from under, and after it lands it needs a moment.
##
## Or one of the forest's restless spirits, come for the village: ember wisps floating up off the
## burned peat; tuyul, who go for salvage and run off with it; charred saplings walking on their
## roots; smoke monkeys, who leap like the dogs and hide in their own smoke; and pocong, wrapped in
## their shrouds, who can only hop, and go over when they're hit hard. A spirit leaves nothing
## lying when it falls: it goes out.

enum State { RUNNING, CROUCHING, LUNGING, RECOVERING }

## Each kind: how fast it runs, how fast it gets back up to pace (meters a second each second),
## its bite and how often, its health, its size, its mass against a rat's one (a hit's push is
## shared over it) and the experience its fall is worth. Dogs add their lunge.
const KINDS := {
	"rat": {
		"speed": 1.7, "grip": 12.0, "bite": 1.0, "bite_interval": 0.8, "health": 2.0,
		"radius": 0.08, "tall": 0.1, "heft": 1.0, "worth": 1,
	},
	"dog": {
		"speed": 3.1, "grip": 9.0, "bite": 2.0, "bite_interval": 1.2, "health": 9.0,
		"radius": 0.22, "tall": 0.5, "heft": 4.0, "worth": 4,
		"lunge_reach": 1.6, "crouch_time": 0.35, "lunge_speed": 6.0, "lunge_lift": 2.2, "recover_time": 0.9,
	},
	# The Rat Baron: the first area's boss, as big as a dog, a bottle cap for a crown. It calls
	# rats in around it as it comes.
	"rat_baron": {
		"speed": 1.5, "grip": 8.0, "bite": 3.0, "bite_interval": 1.0, "health": 160.0,
		"radius": 0.3, "tall": 0.34, "heft": 12.0, "worth": 40, "calls": 4, "call_interval": 5.0,
	},
	# The spirits. An ember wisp floats just off the ground, so it goes over what's low, and
	# blades and rounds still meet it.
	"wisp": {
		"speed": 1.9, "grip": 10.0, "bite": 1.0, "bite_interval": 1.0, "health": 1.5,
		"radius": 0.08, "tall": 0.12, "heft": 0.6, "worth": 1, "spirit": true, "hovers": 0.2,
	},
	# A tuyul goes for salvage lying about, or bites what he's carrying off him, and runs for the
	# trees with it: caught, he drops it.
	"tuyul": {
		"speed": 2.5, "grip": 14.0, "bite": 0.5, "bite_interval": 0.8, "health": 4.0,
		"radius": 0.08, "tall": 0.16, "heft": 1.0, "worth": 2, "spirit": true, "steals": true,
	},
	"sapling": {
		"speed": 0.8, "grip": 6.0, "bite": 2.5, "bite_interval": 1.4, "health": 24.0,
		"radius": 0.17, "tall": 0.6, "heft": 6.0, "worth": 5, "spirit": true,
	},
	"monkey": {
		"speed": 3.2, "grip": 10.0, "bite": 1.5, "bite_interval": 1.0, "health": 6.0,
		"radius": 0.14, "tall": 0.35, "heft": 2.5, "worth": 3, "spirit": true, "smokes": true,
		"lunge_reach": 2.2, "crouch_time": 0.3, "lunge_speed": 6.5, "lunge_lift": 2.6, "recover_time": 0.7,
	},
	# A pocong hops: a push and a lift each time, and nothing to steer with in the air. A hit that
	# would throw it this hard (over its heft) knocks it flat, and it struggles to get up.
	"pocong": {
		"speed": 2.3, "grip": 30.0, "bite": 2.0, "bite_interval": 1.0, "health": 10.0,
		"radius": 0.12, "tall": 0.5, "heft": 3.0, "worth": 3, "spirit": true,
		"hop_lift": 1.5, "hop_rest": 0.25, "topples": 0.8, "flat_for": 1.6,
	},
}
## How far off a tuyul can tell salvage is lying, in meters.
const SNIFFS := 8.0

var kind := "rat"
var body := Body.new()
var health := 2.0
## Experience its fall is worth to the crew.
var worth := 1
## Where it ambles when there's no cat to run at, or nowhere (INF).
var wander_to := Vector2.INF
var bite_ready_in := 0.0
var state := State.RUNNING
## The time left in a crouch or a recovery, and the way a crouch will lunge.
var state_for := 0.0
var lunge_direction := Vector2.RIGHT
## What's afflicting it: poison and fire, as {dps, left, by}, slowing, as {share, left}; and how
## long it's down from a trip.
var afflictions := {}
var tripped_for := 0.0
## How long until it calls the horde in again, if it's one that calls.
var call_in := 2.0
## Where it's going instead of at a cat, or nowhere (INF): a tuyul after salvage, or off into the
## trees with it. And the salvage it's carrying.
var errand := Vector2.INF
var carrying := 0


func _init(creature_kind := "rat") -> void:
	kind = creature_kind
	health = stat("health")
	worth = stat("worth")
	body.radius = stat("radius")
	body.tall = stat("tall")
	body.kind = kind
	body.hovers = KINDS[kind].get("hovers", 0.0)
	body.height = body.hovers


## Whether it's one of the forest's spirits, which leave nothing lying when they fall.
func spirit() -> bool:
	return KINDS[kind].get("spirit", false)


func hops() -> bool:
	return KINDS[kind].has("hop_lift")


func stat(name: String) -> Variant:
	return KINDS[kind][name]


func alive() -> bool:
	return health > 0.0


func lunging() -> bool:
	return state == State.LUNGING


func tripped() -> bool:
	return tripped_for > 0.0


## How much of its pace it has, slowed or not.
func pace() -> float:
	var slowed: Dictionary = afflictions.get("slow", {})
	return 1.0 - (slowed.share if slowed.get("left", 0.0) > 0.0 else 0.0)


func step(delta: float, prey: Cat, arena: Arena = null) -> void:
	bite_ready_in = maxf(bite_ready_in - delta, 0.0)
	# A hop's rest is taken on the ground.
	if not (hops() and body.airborne()):
		state_for = maxf(state_for - delta, 0.0)
	if KINDS[kind].has("calls") and arena != null:
		call_in -= delta
		if call_in <= 0.0:
			call_in = stat("call_interval")
			for index in int(stat("calls")):
				arena.add_creature(body.position + Vector2.from_angle(TAU * index / stat("calls")) * (body.radius + 0.3))
			arena.events.append({"position": body.position, "height": 0.3, "direction": Vector2.ZERO, "killed": false, "by": "call", "giant": false, "kind": kind})
	if tripped_for > 0.0:
		# Down on its side: it slides to a stop and gets up when it can.
		tripped_for = maxf(tripped_for - delta, 0.0)
		body.slide(delta)
		body.step(delta)
		return
	match state:
		State.CROUCHING:
			# Bunched, still: the warning a lunge is coming.
			body.velocity = body.velocity.move_toward(Vector2.ZERO, float(stat("grip")) * 2.0 * delta)
			if state_for <= 0.0:
				state = State.LUNGING
				body.velocity = Vector2.ZERO
				body.push(lunge_direction * float(stat("lunge_speed")), stat("lunge_lift"))
				if arena != null:
					arena.events.append({"position": body.position, "height": 0.3, "direction": lunge_direction, "killed": false, "by": "lunge", "giant": false, "kind": kind})
		State.LUNGING:
			# A leap is a throw: no steering in the air. It ends where it lands.
			if not body.airborne():
				state = State.RECOVERING
				state_for = stat("recover_time")
				if KINDS[kind].get("smokes", false) and arena != null:
					arena.add_smoke(body.position)
		State.RECOVERING:
			body.slide(delta)
			if state_for <= 0.0:
				state = State.RUNNING
		State.RUNNING:
			_run(delta, prey, arena)
	body.step(delta)


func _run(delta: float, prey: Cat, arena: Arena) -> void:
	if body.airborne():
		return
	var wanted := Vector2.ZERO
	if errand.is_finite():
		var going: Vector2 = arena.way(body.position, errand) if arena != null else (errand - body.position).normalized()
		wanted = going * float(stat("speed")) * pace()
	elif prey != null and prey.alive():
		var toward := prey.body.position - body.position
		# Around whatever stands between, if anything does.
		var going: Vector2 = arena.way(body.position, prey.body.position) if arena != null else toward.normalized()
		wanted = going * float(stat("speed")) * pace()
		# A dog close enough crouches to lunge, committing to where he is now.
		if KINDS[kind].has("lunge_reach") and toward.length() < float(stat("lunge_reach")) and bite_ready_in <= 0.0:
			state = State.CROUCHING
			state_for = stat("crouch_time")
			lunge_direction = toward.normalized()
			return
	elif wander_to.is_finite():
		wanted = (wander_to - body.position).limit_length(1.0) * float(stat("speed")) * 0.35
	if hops():
		_hop(wanted, delta)
		return
	# Feet on the ground: it claws back to the pace it wants, so a knock carries it a way.
	body.velocity = body.velocity.move_toward(wanted, float(stat("grip")) * delta)


## Bound up in its shroud, it can only hop: it stops dead where it lands, gathers itself, and goes
## again the way it wants to go, at its pace for as long as it's in the air.
func _hop(wanted: Vector2, delta: float) -> void:
	body.velocity = body.velocity.move_toward(Vector2.ZERO, float(stat("grip")) * delta)
	if state_for > 0.0 or wanted == Vector2.ZERO:
		return
	body.velocity = wanted
	body.push(Vector2.ZERO, stat("hop_lift"))
	state_for = stat("hop_rest")
