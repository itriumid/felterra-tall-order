class_name Guardian
extends Giant
## Inyiak Balang, the forest's grandfather: the great tiger who keeps the forest, older than the
## village. It has come for the village because wherever the forest burned, it found cats.
##
## It stalks him, circling at a distance, and with him in reach it crouches, the spot it will land on marked on the ground
## (the warning), then pounces: a real leap through the air, crushing what it lands on and throwing
## what's near, its own spirits too. Landed, it needs a moment to gather itself, and while it does,
## hits land twice as hard. Close, it raises a paw, the sweep it will take marked, and swipes. Now
## and then it roars: what's near is thrown back, and embers come out of the trees at its call.
## Beaten, it doesn't fall: it lies down, and listens.

enum Move { STALKING, CROUCHING, POUNCING, GATHERING, RAISING, SWIPING, ROARING, LYING }

const HEALTH := 900.0
const STALK_SPEED := 1.5
const BODY_RADIUS := 0.5
const BODY_TALL := 1.1
const TIGER_WORTH := 120
## The pounce: from how near and how far, the crouch before it, how hard it leaps up (the arc
## follows from that), what it does landing, how long it gathers itself after, and how soon it can
## again.
const POUNCE_FROM := 2.2
const POUNCE_TO := 6.5
const CROUCH_TIME := 0.8
const POUNCE_LIFT := 3.2
const POUNCE_CRUSH := 0.7
const POUNCE_SHOCK := 1.8
const POUNCE_CRUSH_DAMAGE := 4.0
const POUNCE_SHOCK_DAMAGE := 1.5
const GATHER_TIME := 1.3
const POUNCE_INTERVAL := 2.5
## How far off it circles him, waiting to pounce.
const CIRCLE_AT := 3.5
## The swipe: its reach, the arc it sweeps, the paw raised before it (the warning), the sweep
## itself, what it does, and how soon it can again.
const SWIPE_REACH := 1.5
const SWIPE_ARC := deg_to_rad(130.0)
const RAISE_TIME := 0.45
const SWIPE_TIME := 0.18
const SWIPE_HEIGHT := 0.5
const SWIPE_DAMAGE := 3.0
const SWIPE_KNOCK := 3.2
const SWIPE_INTERVAL := 1.6
## The roar: how often, how long, how far it throws him back and how hard, and what comes at its
## call: embers, and once it's down to half, saplings too.
const ROAR_INTERVAL := 13.0
const ROAR_TIME := 1.0
const ROAR_REACH := 3.2
const ROAR_KNOCK := 3.5
const ROAR_CALLS := 6
const ROAR_SAPLINGS := 3

var move := Move.STALKING
## The time left in the move it's making.
var move_for := 0.0
## Where a pounce will land.
var pounce_to := Vector2.ZERO
var pounce_in := 1.5
var swipe_in := 0.0
var roar_in := 6.0


func _init() -> void:
	kind = "tiger"
	most_health = HEALTH
	health = HEALTH
	speed = STALK_SPEED
	worth = TIGER_WORTH
	body.radius = BODY_RADIUS
	body.tall = BODY_TALL
	body.kind = kind
	# It lands from a pounce on its paws, not bouncing.
	body.restitution = 0.0


func standing() -> bool:
	return move != Move.LYING


## Hurt by a hit, twice as hard while it gathers itself after a pounce. Beaten, it lies down.
func take(damage: float, direction: Vector2) -> void:
	if not alive():
		return
	health -= damage * (2.0 if move == Move.GATHERING else 1.0)
	_last_knock = direction
	if not alive():
		health = 0.0
		move = Move.LYING
		body.velocity = Vector2.ZERO


func step(delta: float, arena: Arena) -> void:
	pounce_in = maxf(pounce_in - delta, 0.0)
	swipe_in = maxf(swipe_in - delta, 0.0)
	move_for = maxf(move_for - delta, 0.0)
	match move:
		Move.STALKING: _stalk(delta, arena)
		Move.CROUCHING: _crouch(arena)
		Move.POUNCING: _pounce(arena)
		Move.GATHERING:
			body.velocity = Vector2.ZERO
			if move_for <= 0.0:
				move = Move.STALKING
		Move.RAISING:
			body.velocity = Vector2.ZERO
			if move_for <= 0.0:
				move = Move.SWIPING
				move_for = SWIPE_TIME
				arena.events.append({"position": body.position, "height": 0.4, "direction": facing, "killed": false, "by": "swipe", "giant": true, "kind": kind})
		Move.SWIPING: _swipe(arena)
		Move.ROARING:
			body.velocity = Vector2.ZERO
			if move_for <= 0.0:
				move = Move.STALKING
		Move.LYING:
			body.velocity = Vector2.ZERO
	if snared_for > 0.0:
		snared_for = maxf(snared_for - delta, 0.0)
		if move == Move.STALKING:
			body.velocity = Vector2.ZERO
	if standing():
		body.step(delta)


func _stalk(delta: float, arena: Arena) -> void:
	roar_in -= delta
	var prey := arena.nearest_cat(body.position)
	if prey == null:
		var toward_wander := (wander_to - body.position) if wander_to.is_finite() else Vector2.ZERO
		body.velocity = toward_wander.limit_length(1.0) * speed * 0.6
		return
	var toward := prey.body.position - body.position
	facing = arena.way(body.position, prey.body.position, true)
	if roar_in <= 0.0:
		_roar(arena)
		return
	var distance := toward.length()
	if distance <= SWIPE_REACH * 0.9 and swipe_in <= 0.0:
		# It commits to the way he is now; the raised paw is his warning to be elsewhere.
		move = Move.RAISING
		move_for = RAISE_TIME
		facing = toward.normalized()
		sweep_center = facing.angle()
		saw_angle = sweep_center - SWIPE_ARC * 0.5
		body.velocity = Vector2.ZERO
		return
	if distance >= POUNCE_FROM and distance <= POUNCE_TO and pounce_in <= 0.0 and arena.clear_between(body.position, prey.body.position, BODY_TALL):
		# It lands where he is now: the crouch is the time he has to be somewhere else.
		move = Move.CROUCHING
		move_for = CROUCH_TIME
		pounce_to = prey.body.position
		facing = toward.normalized()
		body.velocity = Vector2.ZERO
		arena.events.append({"position": pounce_to, "height": 0.0, "direction": facing, "killed": false, "by": "crouch", "giant": true, "kind": kind})
		return
	# A hunting cat: it closes to pouncing distance, then circles him there until it's ready.
	if distance > CIRCLE_AT + 0.5:
		body.velocity = facing * speed
	elif distance < POUNCE_FROM:
		body.velocity = -toward.normalized() * speed * 0.5
	else:
		body.velocity = toward.normalized().orthogonal() * speed * 0.6


func _crouch(arena: Arena) -> void:
	body.velocity = Vector2.ZERO
	if move_for > 0.0:
		return
	move = Move.POUNCING
	# Up as hard as it leaps, and along the ground fast enough to come down on the spot.
	var flight := 2.0 * POUNCE_LIFT / Body.GRAVITY
	body.velocity = (pounce_to - body.position) / flight
	body.push(Vector2.ZERO, POUNCE_LIFT)
	arena.events.append({"position": body.position, "height": 0.3, "direction": facing, "killed": false, "by": "pounce", "giant": true, "kind": kind})


func _pounce(arena: Arena) -> void:
	if body.airborne():
		return
	body.velocity = Vector2.ZERO
	move = Move.GATHERING
	move_for = GATHER_TIME
	pounce_in = POUNCE_INTERVAL
	arena.stomp(self, body.position, POUNCE_CRUSH, POUNCE_SHOCK, POUNCE_CRUSH_DAMAGE, POUNCE_SHOCK_DAMAGE)


## The paw sweeps across its arc; each step, what it passed through is struck.
func _swipe(arena: Arena) -> void:
	var before := saw_angle
	saw_angle = sweep_center - SWIPE_ARC * 0.5 + SWIPE_ARC * (1.0 - move_for / SWIPE_TIME)
	arena.saw(self, before, saw_angle, SWIPE_REACH, SWIPE_HEIGHT, SWIPE_DAMAGE, SWIPE_KNOCK, "claws")
	if move_for <= 0.0:
		move = Move.STALKING
		swipe_in = SWIPE_INTERVAL


## It roars: what's near is thrown back off it, and the forest answers, out of the trees.
func _roar(arena: Arena) -> void:
	roar_in = ROAR_INTERVAL
	move = Move.ROARING
	move_for = ROAR_TIME
	body.velocity = Vector2.ZERO
	arena.events.append({"position": body.position, "height": 0.9, "direction": facing, "killed": false, "by": "roar", "giant": true, "kind": kind, "radius": ROAR_REACH})
	for cat in arena.cats:
		var apart := cat.body.position - body.position
		if apart.length() <= ROAR_REACH and not cat.body.airborne():
			cat.body.push((apart.normalized() if apart.length() > 0.001 else Vector2.DOWN) * ROAR_KNOCK, 0.6)
	for index in ROAR_CALLS:
		arena.add_creature(arena.edge_point(), "wisp")
	if health <= most_health * 0.5:
		var gate := arena.edge_point()
		for index in ROAR_SAPLINGS:
			arena.add_creature((gate + Vector2(arena.random.randf_range(-0.6, 0.6), arena.random.randf_range(-0.6, 0.6))).clamp(Vector2.ONE * 0.3, arena.size - Vector2.ONE * 0.3), "sapling")
