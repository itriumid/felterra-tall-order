class_name Weapon
extends RefCounted
## A weapon in a cat's paw. Ranged weapons fire rounds; melee weapons swing a blade through an
## arc, and hit whatever the blade passes through on its way.

enum Kind { RANGED, MELEE }

var name := ""
var kind := Kind.RANGED
## Paws it takes: a cat has two.
var hands := 1
var reach := 6.0
var interval := 0.45
var damage := 2.0
## How hard a hit shoves what it strikes, along and up, in meters a second. Arcade-strong: a
## real round wouldn't throw a rat, but a thrown rat is how a hit reads.
var knock := 1.4
var lift := 1.0
var ready_in := 0.0
## Its level, from 1 to 5, and what its levels have added: extra damage and extra speed, as
## shares.
var level := 1
var power := 0.0
var tempo := 0.0

# Ranged: muzzle speed in meters a second, spread either side in radians.
var muzzle_speed := 100.0
var spread := deg_to_rad(2.0)
## Rounds fired, so the view can flash the muzzle and kick the gun back.
var rounds_fired := 0

# Melee: the arc the blade sweeps, in radians, and how long a swing takes.
var arc := deg_to_rad(110.0)
var swing_time := 0.14
## The blade's height above the ground, from paw to tip.
var blade_low := 0.0
var blade_high := 0.3
## The swing in progress: seconds left, the angle it sweeps from, and what it has hit.
var swinging_for := 0.0
var swing_start := 0.0
var swing_direction := 1.0
var blade_angle := 0.0
var swings := 0
var _struck := {}


## What every cat may start with: a short blade, quick and close.
static func knife() -> Weapon:
	var weapon := Weapon.new()
	weapon.name = "knife"
	weapon.kind = Kind.MELEE
	weapon.reach = 0.45
	weapon.interval = 0.38
	weapon.damage = 2.0
	weapon.knock = 1.8
	weapon.lift = 0.8
	return weapon


## Or a handgun: slow, short, but every round tells.
static func handgun() -> Weapon:
	var weapon := Weapon.new()
	weapon.name = "handgun"
	return weapon


static func submachine_gun() -> Weapon:
	var weapon := Weapon.new()
	weapon.name = "submachine_gun"
	weapon.reach = 7.0
	weapon.interval = 0.12
	weapon.muzzle_speed = 120.0
	weapon.spread = deg_to_rad(3.0)
	weapon.damage = 1.0
	weapon.knock = 1.6
	weapon.lift = 1.2
	return weapon


static func named(weapon_name: String) -> Weapon:
	match weapon_name:
		"knife": return knife()
		"submachine_gun": return submachine_gun()
	return handgun()


func swinging() -> bool:
	return swinging_for > 0.0


## What it does in this cat's paw, with her stats and its own levels.
func hit_for(cat: Cat) -> float:
	return damage * (1.0 + power + cat.damage_bonus)


func interval_for(cat: Cat) -> float:
	return interval / (1.0 + tempo + cat.attack_speed_bonus)


func reach_for(cat: Cat) -> float:
	return reach * (1.0 + cat.reach_bonus)


func step(delta: float, cat: Cat, arena: Arena) -> void:
	ready_in = maxf(ready_in - delta, 0.0)
	if kind == Kind.MELEE:
		_swing(delta, cat, arena)
		return
	var target := arena.target_for(cat.body.position, reach_for(cat), cat.aim_mode)
	if target == null or ready_in > 0.0:
		return
	ready_in += interval_for(cat)
	var direction: Vector2 = (target.body.position - cat.body.position).normalized().rotated(arena.random.randf_range(-spread, spread))
	var distance := cat.body.position.distance_to(target.body.position)
	var shot := Shot.new()
	shot.position = cat.body.position + direction * (Cat.RADIUS + 0.05)
	shot.height = cat.body.height + Cat.GUN_HEIGHT
	shot.velocity = direction * muzzle_speed
	# Aimed down at the middle of the target: a round fired level would pass over a rat.
	var time_to_target := maxf(distance / muzzle_speed, 0.001)
	shot.vertical_speed = (target.body.height + target.body.tall * 0.5 - shot.height) / time_to_target
	shot.life = reach_for(cat) * 1.3 / muzzle_speed
	shot.weapon = self
	shot.damage = hit_for(cat)
	shot.shooter = cat
	arena.shots.append(shot)
	rounds_fired += 1


## A swing starts when something is in reach, centered on it, and sweeps across. Each step, the
## blade's sweep from where it was to where it is now finds what it cut through.
func _swing(delta: float, cat: Cat, arena: Arena) -> void:
	if not swinging():
		var target := arena.target_for(cat.body.position, reach_for(cat) + 0.1, cat.aim_mode)
		if target == null or ready_in > 0.0:
			return
		ready_in = interval_for(cat)
		swinging_for = swing_time
		# Alternate forehand and backhand, as a blade is swung.
		swing_direction = -swing_direction
		swing_start = (target.body.position - cat.body.position).angle() - swing_direction * arc * 0.5
		blade_angle = swing_start
		swings += 1
		_struck.clear()
	var before := blade_angle
	swinging_for = maxf(swinging_for - delta, 0.0)
	var done := 1.0 - swinging_for / swing_time
	blade_angle = swing_start + swing_direction * arc * done
	for creature in arena.cut(cat.body.position, cat.body.height, reach_for(cat), self, before, blade_angle):
		if _struck.has(creature):
			continue
		_struck[creature] = true
		var outward: Vector2 = (creature.body.position - cat.body.position).normalized()
		var along_blade := outward.orthogonal() * swing_direction
		arena.strike(creature, hit_for(cat), (outward + along_blade * 0.6).normalized(), knock, lift, "blade", cat)
