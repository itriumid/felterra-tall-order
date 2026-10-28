class_name Companion
extends RefCounted
## The spirits' gift: a tiger cub, Inyiak Balang's grandchild, bound into the jimat he wears at
## his collar. The cats have no magic of their own; this is the forest's, lent. It walks at his
## heel, and when something comes near him it runs at it and pounces, a real leap, and what it
## lands among takes its element: ember sets them burning, smoke slows them in a cloud, root holds
## them where they stand, and river throws them off.
##
## It's ranked at the shrine, slowly, with offerings from the groves; its element is chosen there
## too. In a run, the charm takes levels from the cards, as support does. A spirit, it can't be
## hurt, and it never goes far from him.

const ELEMENTS: Array[String] = ["ember", "smoke", "root", "river"]
## How fast it runs, how far from him it watches, how far from him it will ever go, and where at
## his side it walks: behind him and off to one side, as he faces.
const SPEED := 5.5
const WATCH := 4.5
const LEASH := 6.0
const HEEL := Vector2(-0.7, 0.45)
const BODY_RADIUS := 0.18
const BODY_TALL := 0.3
## The pounce: from how near, how hard it leaps up, how wide it lands, what it does, and how soon
## it can again.
const POUNCE_FROM := 2.2
const POUNCE_LIFT := 2.2
const STRIKE_RADIUS := 0.7
const STRIKE_DAMAGE := 3.0
const STRIKE_KNOCK := 1.2
const POUNCE_INTERVAL := 1.8
## What each rank at the shrine adds to what it does, past the first.
const RANK_SHARE := 0.2
const MOST_RANK := 10
## Ember: how hard what it lands on burns, and for how long.
const EMBER_BURN := 1.2
const EMBER_TIME := 3.0
## Smoke: how wide the cloud it lands in, how much it slows, and for how long.
const SMOKE_REACH := 1.5
const SMOKE_SLOW := 0.5
const SMOKE_TIME := 3.0
## Root: how long it holds the horde where they stand, and a giant by the boots.
const ROOT_HOLD := 1.6
const ROOT_GIANT_HOLD := 1.0
## River: how wide the wave it lands in, and how hard it throws.
const RIVER_REACH := 1.5
const RIVER_KNOCK := 4.0
const RIVER_LIFT := 1.4

var element := "ember"
## Its rank from the shrine, and its level in the run, from the cards: past the top, mastery.
var rank := 1
var level := 1
var power := 0.0
var tempo := 0.0
var body := Body.new()
var facing := Vector2.RIGHT
## How far it's run, for its walk cycle; and its pounces landed, counted, for the view and the
## sound.
var ran := 0.0
var pounces := 0
var _pounce_in := 0.0
var _leaping := false


func _init(with_element := "ember", with_rank := 1) -> void:
	element = with_element
	rank = clampi(with_rank, 1, MOST_RANK)
	body.radius = BODY_RADIUS
	body.tall = BODY_TALL
	body.kind = "cub"
	body.restitution = 0.0


## How much harder than its first rank and level it hits.
func share(cat: Cat) -> float:
	return 1.0 + RANK_SHARE * (rank - 1) + power + cat.damage_bonus


func step(delta: float, cat: Cat, arena: Arena) -> void:
	_pounce_in = maxf(_pounce_in - delta * (1.0 + tempo), 0.0)
	if _leaping:
		body.step(delta)
		if not body.airborne():
			_leaping = false
			_land(cat, arena)
		return
	var heel := cat.body.position + facing_offset(cat)
	var wanted := heel
	var from_him := body.position.distance_to(cat.body.position)
	var target: Object = arena.target_for(cat.body.position, WATCH, "nearest") if from_him <= LEASH else null
	if target != null:
		var toward: Vector2 = target.body.position - body.position
		facing = toward.normalized() if toward.length() > 0.001 else facing
		if toward.length() <= POUNCE_FROM and _pounce_in <= 0.0:
			_leap(target.body.position)
			return
		# Waiting to pounce again, it keeps close by what it's after.
		wanted = target.body.position - facing * (POUNCE_FROM * 0.6 if _pounce_in > 0.0 else 0.0)
	var to_wanted := wanted - body.position
	var pace := SPEED if to_wanted.length() > 0.3 else 0.0
	body.velocity = to_wanted.normalized() * minf(pace, to_wanted.length() / delta) if pace > 0.0 else Vector2.ZERO
	if body.velocity.length_squared() > 0.01 and target == null:
		facing = body.velocity.normalized()
	ran += body.velocity.length() * delta
	body.step(delta)


## Where at his side it walks, turned the way he faces.
func facing_offset(cat: Cat) -> Vector2:
	var forward := cat.facing if cat.facing.length_squared() > 0.001 else Vector2.RIGHT
	return forward * HEEL.x + forward.orthogonal() * HEEL.y


## Up and onto a spot: the leap is through the air, fast enough along the ground to come down on it.
func _leap(to: Vector2) -> void:
	var flight := 2.0 * POUNCE_LIFT / Body.GRAVITY
	body.velocity = (to - body.position) / flight
	body.push(Vector2.ZERO, POUNCE_LIFT)
	_leaping = true


## Down among them: what's under it is struck, and takes its element.
func _land(cat: Cat, arena: Arena) -> void:
	body.velocity = Vector2.ZERO
	_pounce_in = POUNCE_INTERVAL
	pounces += 1
	var strength := share(cat)
	arena.events.append({"position": body.position, "height": 0.0, "direction": facing, "killed": false, "by": "cub_" + element, "giant": false, "kind": "cub",
		"radius": SMOKE_REACH if element == "smoke" else (RIVER_REACH if element == "river" else STRIKE_RADIUS)})
	var reach := STRIKE_RADIUS
	if element == "smoke":
		reach = SMOKE_REACH
	elif element == "river":
		reach = RIVER_REACH
	for target: Object in arena.targets_near(body.position, reach):
		var apart: Vector2 = target.body.position - body.position
		var away := apart.normalized() if apart.length() > 0.001 else facing
		var struck: bool = apart.length() <= STRIKE_RADIUS + target.body.radius
		match element:
			"ember":
				arena.strike(target, STRIKE_DAMAGE * strength, away, STRIKE_KNOCK, 0.4, "cub", cat)
				if (target is Creature or target is Giant) and target.alive():
					target.afflictions.burn = {"dps": EMBER_BURN * strength, "left": EMBER_TIME, "by": cat, "tick": 0.0}
			"smoke":
				if struck:
					arena.strike(target, STRIKE_DAMAGE * strength, away, STRIKE_KNOCK, 0.4, "cub", cat)
				if target is Creature and target.alive():
					target.afflictions.slow = {"share": SMOKE_SLOW, "left": SMOKE_TIME}
			"root":
				arena.strike(target, STRIKE_DAMAGE * strength, away, 0.0, 0.0, "cub", cat)
				if target is Creature and target.alive():
					target.tripped_for = maxf(target.tripped_for, ROOT_HOLD)
					target.body.velocity = Vector2.ZERO
				elif target is Giant and target.alive():
					target.snared_for = maxf(target.snared_for, ROOT_GIANT_HOLD)
			"river":
				arena.strike(target, STRIKE_DAMAGE * strength * (1.0 if struck else 0.5), away, RIVER_KNOCK, RIVER_LIFT, "cub", cat)
