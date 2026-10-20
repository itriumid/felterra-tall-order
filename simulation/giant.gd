class_name Giant
extends RefCounted
## A human at real scale: a logging worker, five or six times a cat's height. Slow, heavy, and
## dangerous underfoot. He walks at the nearest cat and stomps; felled, he topples like the tall
## body he is and crushes what he lands on.

enum State { WALKING, WINDING, FALLING, FALLEN }

const TALL := 1.75
const RADIUS := 0.25
## Against a rat's one: a round that throws a rat barely moves him.
const HEFT := 40.0
const SPEED := 1.1
const MOST_HEALTH := 60.0
## The stomp: he goes for it within this reach, raises the boot for WIND_TIME (its shadow on the
## ground is the warning), and slams it down.
const STOMP_REACH := 0.9
const WIND_TIME := 0.55
const STOMP_INTERVAL := 2.2
const BOOT_HEIGHT := 0.35
## Under the boot is crushed; the shockwave around it throws and stings.
const CRUSH_RADIUS := 0.3
const SHOCK_RADIUS := 1.3
const CRUSH_DAMAGE := 3.0
const SHOCK_DAMAGE := 1.0
const SHOCK_KNOCK := 2.2
## Falling, he crushes a strip this wide along his length.
const FALLEN_WIDTH := 0.35
const FALL_DAMAGE := 4.0
const WORTH := 15

var body := Body.new()
var health := MOST_HEALTH
var state := State.WALKING
var facing := Vector2.RIGHT
var stomp_ready_in := 1.0
var wind_for := 0.0
## Where the raised boot will come down, and how high it is.
var foot := Vector2.ZERO
var foot_height := 0.0
## The fall: the angle from upright, how fast it's growing, and which way along the ground.
var fall_angle := 0.0
var fall_speed := 0.0
var fall_direction := Vector2.RIGHT
var fallen_for := 0.0
var _last_knock := Vector2.RIGHT
## Where he walks when there's no cat to go after, or nowhere (INF).
var wander_to := Vector2.INF


func _init() -> void:
	body.radius = RADIUS
	body.tall = TALL


func alive() -> bool:
	return health > 0.0


func standing() -> bool:
	return state == State.WALKING or state == State.WINDING


## Hurt by a hit; the direction it came from decides which way he falls.
func take(damage: float, direction: Vector2) -> void:
	if not alive():
		return
	health -= damage
	_last_knock = direction
	if not alive():
		state = State.FALLING
		fall_direction = direction.normalized() if direction.length_squared() > 0.0 else facing
		# A nudge off true: a body balanced dead upright never starts to fall.
		fall_angle = 0.05


func step(delta: float, arena: Arena) -> void:
	match state:
		State.WALKING: _walk(delta, arena)
		State.WINDING: _wind(delta, arena)
		State.FALLING: _fall(delta, arena)
		State.FALLEN: fallen_for += delta
	if standing():
		body.step(delta)


func _walk(delta: float, arena: Arena) -> void:
	stomp_ready_in = maxf(stomp_ready_in - delta, 0.0)
	var prey := arena.nearest_cat(body.position)
	if prey == null:
		var toward_wander := (wander_to - body.position) if wander_to.is_finite() else Vector2.ZERO
		body.velocity = toward_wander.limit_length(1.0) * SPEED * 0.6
		if toward_wander.length_squared() > 0.01:
			facing = toward_wander.normalized()
		return
	var toward := prey.body.position - body.position
	facing = toward.normalized()
	if toward.length() <= STOMP_REACH and stomp_ready_in <= 0.0:
		state = State.WINDING
		wind_for = WIND_TIME
		# He stomps where she is now: she has the wind-up to get out from under it.
		foot = prey.body.position
		body.velocity = Vector2.ZERO
		return
	body.velocity = facing * SPEED if toward.length() > STOMP_REACH * 0.6 else Vector2.ZERO


func _wind(delta: float, arena: Arena) -> void:
	wind_for = maxf(wind_for - delta, 0.0)
	var done := 1.0 - wind_for / WIND_TIME
	# Up for most of it, then down hard.
	foot_height = BOOT_HEIGHT * (sin(done * PI * 0.5 / 0.8) if done < 0.8 else (1.0 - done) / 0.2)
	if wind_for <= 0.0:
		foot_height = 0.0
		state = State.WALKING
		stomp_ready_in = STOMP_INTERVAL
		arena.stomp(self, foot)


## A tall body toppling about its feet: for a rod pivoting at one end, the angle accelerates by
## (3g / 2L) · sin(angle). When it reaches the ground, it lands along its length.
func _fall(delta: float, arena: Arena) -> void:
	fall_speed += 1.5 * Body.GRAVITY / TALL * sin(fall_angle) * delta
	fall_angle += fall_speed * delta
	if fall_angle >= PI * 0.5:
		fall_angle = PI * 0.5
		state = State.FALLEN
		arena.land(self)
