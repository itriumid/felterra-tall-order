class_name Support
extends RefCounted
## What she carries on her back, beside what's in her paws: one drone and one thing she sets
## down. She starts with neither; each comes with its mount on her pack, and works on its own.
##
## The gun drone docks on her pack. When something comes in reach it lifts off, hovers off her
## shoulder and fires down at it, and when it's quiet it settles back. The meriam bambu, the
## bamboo cannon, rides strapped across the pack until something comes in reach; she sets it down
## where she stands and it lobs heavy stones that burst where they land. A bamboo tube only takes
## so many shots before it cracks, so when it does, she cuts a new one. Mines ride in pouches on
## the straps: while enemies are near, she drops one every few seconds, and the first foot on one
## sets it off, a giant's boot included.

## Which slot each takes: a drone, or something set down. One of each.
const SLOTS := {"gun_drone": "drone", "meriam_bambu": "set_down", "mines": "set_down"}

## The drone: where it hovers, off her shoulder and up; how fast it flies and turns; and how long
## it waits with nothing in reach before it docks.
const DRONE_HEIGHT := 1.1
const DRONE_OFFSET := Vector2(-0.45, -0.35)
const DRONE_SPEED := 6.0
const DRONE_GRIP := 14.0
const DRONE_LINGER := 1.5
## Docked, it sits on top of her pack.
const DOCKED_HEIGHT := 0.42

## The meriam bambu: the shots a tube takes before it cracks, and how long a new one takes her.
const TUBE_SHOTS := 8
const REBUILD_TIME := 6.0
## Where the stone leaves the tube, above the ground.
const MOUTH_HEIGHT := 0.18

## Mines: one dropped this often while an enemy is this close, no more than so many down at once.
## Each arms a moment after it lands, and goes off when something is this close to it.
const MINE_INTERVAL := 3.5
const MINE_WATCH := 5.0
const MOST_MINES := 4
const ARM_TIME := 0.5
const TRIGGER_REACH := 0.12
const MINE_BLAST := 1.1
const MINE_DAMAGE := 6.0
const MINE_KNOCK := 3.5
const MINE_LIFT := 2.5

var name := ""
var slot := ""
## Its level, from 1, like a weapon's: past the top, mastery.
var level := 1
var power := 0.0
var tempo := 0.0
## What it fires, for the drone and the cannon.
var weapon: Weapon
## Where it is: the drone in the air, the cannon on the ground. Mines are each their own.
var body := Body.new()
## The drone off her pack, or the cannon set down.
var deployed := false
var _idle_for := 0.0
## The cannon: shots left in this tube, and the time until a cracked one is replaced.
var shots_left := TUBE_SHOTS
var rebuilt_in := 0.0
## Tubes that have cracked, counted, so the view and the sound know when one does.
var cracks := 0
## Mines on the ground, as {body, armed_in}, and the time until she can drop the next.
var mines: Array[Dictionary] = []
var _next_mine_in := 0.0
## Mines that have gone off, and been dropped, counted.
var mines_dropped := 0


static func named(support_name: String) -> Support:
	var support := Support.new()
	support.name = support_name
	support.slot = SLOTS[support_name]
	match support_name:
		"gun_drone":
			var gun := Weapon.new()
			gun.name = "gun_drone"
			gun.reach = 6.5
			gun.interval = 0.55
			gun.damage = 1.2
			gun.muzzle_speed = 90.0
			# Steadier than a paw: it hovers still to fire.
			gun.spread = deg_to_rad(1.5)
			gun.knock = 1.0
			gun.lift = 0.6
			support.weapon = gun
			support.body.radius = 0.12
			support.body.tall = 0.1
		"meriam_bambu":
			var cannon := Weapon.new()
			cannon.name = "meriam_bambu"
			cannon.reach = 8.0
			cannon.interval = 1.4
			cannon.damage = 5.0
			cannon.muzzle_speed = 9.0
			cannon.spread = deg_to_rad(4.0)
			cannon.lobbed = true
			cannon.blast = 0.7
			cannon.knock = 3.0
			cannon.lift = 2.0
			support.weapon = cannon
			support.body.radius = 0.2
			support.body.tall = 0.25
	return support


## What a hit from it does, with her stats and its own levels: the same rule as a weapon's.
func hit_for(cat: Cat) -> float:
	return _base_damage() * (1.0 + power + cat.damage_bonus)


func _base_damage() -> float:
	return MINE_DAMAGE if name == "mines" else weapon.damage


func step(delta: float, cat: Cat, arena: Arena) -> void:
	if weapon != null:
		# Its levels and her gear count, as for anything she fights with.
		weapon.power = power
		weapon.tempo = tempo
	match name:
		"gun_drone": _fly(delta, cat, arena)
		"meriam_bambu": _cannon(delta, cat, arena)
		"mines": _mines(delta, cat, arena)


## The drone: off the pack while there's something to shoot, docked when there isn't.
func _fly(delta: float, cat: Cat, arena: Arena) -> void:
	var in_reach := arena.target_for(cat.body.position, weapon.reach_for(cat), cat.aim_mode) != null
	_idle_for = 0.0 if in_reach else _idle_for + delta
	if not deployed:
		body.position = cat.body.position
		body.height = cat.body.height + DOCKED_HEIGHT
		body.velocity = cat.body.velocity
		if in_reach and cat.alive():
			deployed = true
		return
	var docking := _idle_for >= DRONE_LINGER or not cat.alive()
	var goal := cat.body.position if docking else cat.body.position + DRONE_OFFSET
	var goal_height := cat.body.height + (DOCKED_HEIGHT if docking else DRONE_HEIGHT)
	# Thrust toward where it wants to be, capped: it trails her a little, the way a drone does.
	var wanted := (goal - body.position) * 4.0
	body.velocity = body.velocity.move_toward(wanted.limit_length(DRONE_SPEED), DRONE_GRIP * delta)
	body.position += body.velocity * delta
	body.height = move_toward(body.height, goal_height, 2.0 * delta)
	if docking and body.position.distance_to(goal) < 0.08 and absf(body.height - goal_height) < 0.03:
		deployed = false
		return
	if not docking:
		weapon.step(delta, cat, arena, body, 0.0)


## The cannon: set down when something comes in reach, firing until its tube cracks, then a new
## tube for the pack.
func _cannon(delta: float, cat: Cat, arena: Arena) -> void:
	if rebuilt_in > 0.0:
		rebuilt_in = maxf(rebuilt_in - delta, 0.0)
		return
	if not deployed:
		if not cat.alive() or cat.body.airborne():
			return
		if arena.target_for(cat.body.position, weapon.reach_for(cat), cat.aim_mode) == null:
			return
		deployed = true
		shots_left = TUBE_SHOTS
		body.position = cat.body.position
		body.height = 0.0
		body.velocity = Vector2.ZERO
		weapon.ready_in = 0.3
		arena.events.append({"position": body.position, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "set_down", "giant": false, "kind": name})
		return
	if weapon.step(delta, cat, arena, body, MOUTH_HEIGHT):
		shots_left -= 1
		if shots_left <= 0:
			deployed = false
			rebuilt_in = REBUILD_TIME
			cracks += 1
			arena.events.append({"position": body.position, "height": 0.1, "direction": Vector2.ZERO, "killed": false, "by": "crack", "giant": false, "kind": name})


## Mines: dropped where she stands while enemies are near, armed a moment later, and set off by
## the first foot close enough.
func _mines(delta: float, cat: Cat, arena: Arena) -> void:
	_next_mine_in = maxf(_next_mine_in - delta, 0.0)
	var cadence := MINE_INTERVAL / (1.0 + tempo + cat.attack_speed_bonus)
	if _next_mine_in <= 0.0 and mines.size() < MOST_MINES and cat.alive() and not cat.body.airborne() \
			and arena.target_for(cat.body.position, MINE_WATCH, "nearest") != null:
		var mine := Body.new()
		mine.position = cat.body.position
		mine.radius = 0.06
		mine.tall = 0.04
		mines.append({"body": mine, "armed_in": ARM_TIME})
		mines_dropped += 1
		_next_mine_in = cadence
	var left: Array[Dictionary] = []
	for mine in mines:
		mine.armed_in = maxf(mine.armed_in - delta, 0.0)
		var at: Vector2 = mine.body.position
		if mine.armed_in <= 0.0 and arena.stepped_on(at, TRIGGER_REACH):
			arena.blast(at, MINE_BLAST, hit_for(cat), MINE_KNOCK, MINE_LIFT, "mines", cat)
		else:
			left.append(mine)
	mines = left
