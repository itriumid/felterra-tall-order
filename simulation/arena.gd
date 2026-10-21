class_name Arena
extends RefCounted
## One fight: the clearing, the cats, the horde, the rounds in the air and the fallen. Runs
## headless at a fixed step, in meters and seconds.

const STEP := 1.0 / 60.0
## The clearing, in meters. The jungle beyond it is a wall.
const SIZE := Vector2(40.0, 24.0)
## The horde comes faster as a run goes on, up to this many at once.
const SPAWN_RATE := 1.5
const SPAWN_GROWTH := 0.05
const MOST_CREATURES := 600
## Giants come out of the jungle from GIANTS_FROM seconds in, one every GIANT_INTERVAL, no
## more than MOST_GIANTS standing at once; the felled lie where they fall for FELLED_LASTS. From
## CHAINSAW_FROM, every CHAINSAW_EVERY-th giant carries a chainsaw.
const GIANTS_FROM := 25.0
const GIANT_INTERVAL := 40.0
const MOST_GIANTS := 3
## The company's guard dogs come in packs from DOGS_FROM seconds in, one pack every DOG_INTERVAL,
## no more than MOST_DOGS at once.
const DOGS_FROM := 50.0
const DOG_INTERVAL := 35.0
const DOG_PACK := 3
const MOST_DOGS := 12
const FELLED_LASTS := 40.0
const CHAINSAW_FROM := 120.0
const CHAINSAW_EVERY := 2
## A machine comes out of the jungle from MACHINE_FROM seconds in, and another every
## MACHINE_INTERVAL after, one working at a time.
const MACHINE_FROM := 300.0
const MACHINE_INTERVAL := 300.0
## The fallen stay where they lie, up to this many. Past that, the oldest crumble away over
## FADE_TIME seconds rather than vanishing.
const MOST_FALLEN := 600
const FADE_TIME := 1.5
## The cell size of the grid that finds what's near what.
const CELL := 0.2

var cats: Array[Cat] = []
var creatures: Array[Creature] = []
## The giants: walking, falling, or lying where they fell.
var giants: Array[Giant] = []
## The machines, the bosses: working, or wrecked where they stopped.
var machines: Array[Machine] = []
var shots: Array[Shot] = []
var fallen: Array[Body] = []
## The oldest of the fallen crumbling away, as {body, left}: seconds until it's gone.
var fading: Array[Dictionary] = []
var random := RandomNumberGenerator.new()
var time := 0.0
var kills := 0
var giants_felled := 0
var machines_broken := 0
var spawning := true
## The crew's experience, shared: every kill counts for all of them, and every level-up hands
## each cat an offer.
var experience := 0
var level := 1
## What happened this step that the view shows but the simulation doesn't need: hits, as
## {position, height, direction, killed, by}. The view takes them as it draws.
var events: Array[Dictionary] = []
var _since_spawn := 0.0
var _since_giant := GIANT_INTERVAL - GIANTS_FROM
var _giants_sent := 0
var _since_machine := MACHINE_INTERVAL - MACHINE_FROM
var _since_dogs := DOG_INTERVAL - DOGS_FROM
var _grid := {}


func _init(seed_value := 39) -> void:
	random.seed = seed_value


func add_cat(where: Vector2) -> Cat:
	var cat := Cat.new()
	cat.body.position = where
	cats.append(cat)
	return cat


func add_giant(where: Vector2, kind := "worker") -> Giant:
	var giant := Giant.new(kind)
	giant.body.position = where
	giants.append(giant)
	return giant


func add_machine(where: Vector2, heading := 0.0) -> Machine:
	var machine := Machine.new()
	machine.body.position = where
	machine.heading = heading
	machine.head = machine.point(Machine.REST_FORWARD, Machine.BOOM_ROOT.y)
	machines.append(machine)
	return machine


func add_creature(where: Vector2, kind := "rat") -> Creature:
	var creature := Creature.new(kind)
	creature.body.position = where
	creatures.append(creature)
	return creature


func step() -> void:
	time += STEP
	# Who stands where, as the step begins: everything that looks for a creature uses it.
	_build_grid()
	for cat in cats:
		cat.step(STEP, self)
		_keep_inside(cat.body)
	for creature in creatures:
		creature.step(STEP, nearest_cat(creature.body.position), self)
		_keep_inside(creature.body)
	for giant in giants:
		giant.step(STEP, self)
		_keep_inside(giant.body)
	giants = giants.filter(func(giant: Giant) -> bool: return giant.fallen_for < FELLED_LASTS)
	for machine in machines:
		machine.step(STEP, self)
		_keep_inside(machine.body)
	_separate()
	_shoulder_through()
	_wander()
	_bite()
	_fly_shots()
	for body in fallen:
		if body.resting():
			continue
		body.slide(STEP)
		body.step(STEP)
		_keep_inside(body)
	_crumble()
	_spawn()


## What a weapon in reach of a point should go for, by aim mode: a creature or a standing giant,
## or null.
func target_for(where: Vector2, reach: float, mode: String) -> Object:
	var best: Object = null
	var best_score := -INF
	for target in _targets():
		var distance: float = where.distance_to(target.body.position) - target.body.radius
		if distance > reach:
			continue
		# Ties go to the nearer, by a hair.
		var score: float = -distance
		if mode == "toughest":
			score = float(target.health) - distance * 0.001
		elif mode == "crowd":
			score = _crowding(target.body.position) - distance * 0.001
		if score > best_score:
			best_score = score
			best = target
	return best


## Everything there is to fight: the horde and the giants still on their feet.
func _targets() -> Array:
	var targets: Array = []
	targets.append_array(creatures)
	for giant in giants:
		if giant.standing():
			targets.append(giant)
	for machine in machines:
		if machine.standing():
			targets.append(machine)
		if machine.joint.alive():
			targets.append(machine.joint)
	return targets


## How many creatures stand within a few cells of a point.
func _crowding(where: Vector2) -> int:
	var cell := _cell_of(where)
	var count := 0
	for x in range(cell.x - 2, cell.x + 3):
		for y in range(cell.y - 2, cell.y + 3):
			count += (_grid.get(Vector2i(x, y), []) as Array).size()
	return count


## The creatures a blade cut through as it swept from one angle to the next around a cat: within
## its reach, inside the sweep, and at a height the blade passes.
func cut(center: Vector2, height: float, reach: float, weapon: Weapon, from_angle: float, to_angle: float) -> Array:
	var cut_through: Array = []
	var sweep := angle_difference(from_angle, to_angle)
	var cell := _cell_of(center)
	var cells := ceili((reach + 0.1) / CELL)
	for x in range(cell.x - cells, cell.x + cells + 1):
		for y in range(cell.y - cells, cell.y + cells + 1):
			for creature: Creature in _grid.get(Vector2i(x, y), []):
				var offset := creature.body.position - center
				if offset.length() > reach + creature.body.radius:
					continue
				var bottom := creature.body.height
				if bottom > height + weapon.blade_high or bottom + creature.body.tall < height + weapon.blade_low:
					continue
				var into := angle_difference(from_angle, offset.angle())
				# Inside the sweep: the same way round as it, and no further. A creature right
				# against the cat is cut whatever the angle.
				if offset.length() < 0.12 or (signf(into) == signf(sweep) and absf(into) <= absf(sweep)) or absf(into) < 0.05:
					cut_through.append(creature)
	# A giant is cut at whatever of him the blade reaches: at a cat's height, his shins.
	for giant in giants:
		if not giant.standing():
			continue
		var offset := giant.body.position - center
		if offset.length() > reach + giant.body.radius:
			continue
		var into := angle_difference(from_angle, offset.angle())
		if offset.length() < giant.body.radius + 0.12 or (signf(into) == signf(sweep) and absf(into) <= absf(sweep)):
			cut_through.append(giant)
	# A machine is cut where the blade meets it, and its joint while it's down on the ground.
	for machine in machines:
		for part: Object in [machine, machine.joint]:
			if not part.alive() or (part == machine and not machine.standing()):
				continue
			var offset: Vector2 = part.body.position - center
			if offset.length() > reach + part.body.radius:
				continue
			var into := angle_difference(from_angle, offset.angle())
			if offset.length() < part.body.radius + 0.12 or (signf(into) == signf(sweep) and absf(into) <= absf(sweep)):
				cut_through.append(part)
	return cut_through


## The nearest living creature within reach of a point, or null.
func nearest_creature(where: Vector2, reach: float) -> Creature:
	var nearest: Creature = null
	var nearest_distance := reach * reach
	for creature in creatures:
		var distance := where.distance_squared_to(creature.body.position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = creature
	return nearest


## Giants wade through the horde: rats in a giant's way are shoved aside, all the way.
func _shoulder_through() -> void:
	for giant in giants:
		if not giant.standing():
			continue
		var cell := _cell_of(giant.body.position)
		for x in range(cell.x - 2, cell.x + 3):
			for y in range(cell.y - 2, cell.y + 3):
				for creature: Creature in _grid.get(Vector2i(x, y), []):
					var apart := creature.body.position - giant.body.position
					var reach := giant.body.radius + creature.body.radius
					if apart.length() < reach:
						creature.body.position = giant.body.position + (apart.normalized() if apart.length() > 0.001 else Vector2.RIGHT) * reach


## A stomp lands: whatever is under the boot is crushed, and the shockwave throws what's near.
func stomp(giant: Giant, at: Vector2) -> void:
	for creature in creatures.duplicate():
		var apart: Vector2 = creature.body.position - at
		if apart.length() <= Giant.CRUSH_RADIUS:
			strike(creature, 100.0, Vector2.ZERO, 0.0, 0.0, "boot")
		elif apart.length() <= Giant.SHOCK_RADIUS:
			creature.body.push(apart.normalized() * Giant.SHOCK_KNOCK, 1.5)
	for cat in cats:
		var apart := cat.body.position - at
		if apart.length() <= Giant.CRUSH_RADIUS + cat.body.radius:
			cat.hurt(Giant.CRUSH_DAMAGE, apart.normalized() * Giant.SHOCK_KNOCK)
		elif apart.length() <= Giant.SHOCK_RADIUS:
			cat.hurt(Giant.SHOCK_DAMAGE, apart.normalized() * Giant.SHOCK_KNOCK)
	events.append({"position": at, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "stomp", "giant": true})


## A chainsaw sweeping across the ground, from one angle to the next around the giant holding it:
## anything in its reach that it passes, at a cat's height, is cut. His own horde too.
func saw(giant: Giant, from_angle: float, to_angle: float) -> void:
	var sweep := angle_difference(from_angle, to_angle)
	var passes := func(offset: Vector2, radius: float) -> bool:
		if offset.length() > Giant.SAW_REACH + radius or offset.length() < Giant.RADIUS:
			return false
		var into := angle_difference(from_angle, offset.angle())
		return signf(into) == signf(sweep) and absf(into) <= absf(sweep) + 0.02
	for creature in creatures.duplicate():
		if creature.body.height < Giant.SAW_HEIGHT and passes.call(creature.body.position - giant.body.position, creature.body.radius):
			strike(creature, 100.0, (creature.body.position - giant.body.position).normalized(), 2.0, 0.6, "saw")
	for cat in cats:
		var offset := cat.body.position - giant.body.position
		if cat.body.height < Giant.SAW_HEIGHT and passes.call(offset, cat.body.radius):
			if cat.hurt(Giant.SAW_DAMAGE, offset.normalized() * Giant.SAW_KNOCK):
				events.append({"position": cat.body.position, "height": 0.2, "direction": offset.normalized(), "killed": false, "by": "saw", "giant": false, "kind": "cat"})


## A feller buncher's jaws shutting on a point: what's between them is cut, cats, giants and its
## own horde alike.
func jaws(machine: Machine, at: Vector2) -> void:
	events.append({"position": at, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "jaws_shut", "giant": true, "kind": machine.kind})
	for creature: Creature in creatures.duplicate():
		if creature.body.position.distance_to(at) <= Machine.JAW_RADIUS + creature.body.radius and creature.body.height < 1.0:
			strike(creature, 100.0, Vector2.ZERO, 0.0, 0.0, "jaws")
	for giant in giants:
		if giant.standing() and giant.body.position.distance_to(at) <= Machine.JAW_RADIUS + giant.body.radius:
			strike(giant, 30.0, (giant.body.position - at).normalized(), 0.0, 0.0, "jaws")
	for cat in cats:
		var apart := cat.body.position - at
		if apart.length() <= Machine.JAW_RADIUS + cat.body.radius and cat.body.height < 0.6:
			cat.hurt(Machine.BITE_DAMAGE, (apart.normalized() if apart.length() > 0.001 else Vector2.DOWN) * Machine.BITE_KNOCK)


## Whether anything is standing on a point: a creature on the ground, or a giant's boot.
func stepped_on(at: Vector2, reach: float) -> bool:
	var cell := _cell_of(at)
	for x in range(cell.x - 2, cell.x + 3):
		for y in range(cell.y - 2, cell.y + 3):
			for creature: Creature in _grid.get(Vector2i(x, y), []):
				if not creature.body.airborne() and creature.body.position.distance_to(at) <= reach + creature.body.radius:
					return true
	for giant in giants:
		if giant.standing() and giant.body.position.distance_to(at) <= reach + giant.body.radius:
			return true
	for machine in machines:
		if machine.covers(at, reach):
			return true
	return false


## A burst on the ground: everything within its radius is struck and thrown outward, the giants
## at their feet. What set it off names it, for the view and the sound.
func blast(at: Vector2, radius: float, damage: float, knock: float, lift: float, by: String, attacker: Cat = null) -> void:
	events.append({"position": at, "height": 0.0, "direction": Vector2.ZERO, "killed": false, "by": "blast", "giant": false, "kind": by, "radius": radius})
	for creature: Creature in creatures.duplicate():
		var apart := creature.body.position - at
		if apart.length() <= radius + creature.body.radius and creature.body.height < radius:
			strike(creature, damage, apart.normalized() if apart.length() > 0.001 else Vector2.RIGHT, knock, lift, by, attacker)
	for giant in giants:
		var apart := giant.body.position - at
		if giant.standing() and apart.length() <= radius + giant.body.radius:
			strike(giant, damage, apart.normalized() if apart.length() > 0.001 else Vector2.RIGHT, knock, 0.0, by, attacker)
	_strike_machines(at, radius, damage, by, attacker)


## Strikes every machine within reach of a point, and its joint if that's in reach too.
func _strike_machines(at: Vector2, reach: float, damage: float, by: String, attacker: Cat) -> void:
	for machine in machines:
		if machine.joint.alive() and machine.joint.body.position.distance_to(at) <= reach + machine.joint.body.radius:
			strike(machine.joint, damage, Vector2.ZERO, 0.0, 0.0, by, attacker)
		elif machine.standing() and machine.covers(at, reach):
			strike(machine, damage, Vector2.ZERO, 0.0, 0.0, by, attacker)


## The creatures a rolling cat is touching, at heights she passes: what a rolling slash cuts.
func rolled_into(cat: Cat) -> Array[Creature]:
	var touching: Array[Creature] = []
	var cell := _cell_of(cat.body.position)
	for x in range(cell.x - 2, cell.x + 3):
		for y in range(cell.y - 2, cell.y + 3):
			for creature: Creature in _grid.get(Vector2i(x, y), []):
				if creature.alive() and _touching(cat.body, creature.body, 0.06):
					touching.append(creature)
	return touching


## The giants standing over a rolling cat: she's between his legs.
func legs_rolled_between(cat: Cat) -> Array[Giant]:
	var over: Array[Giant] = []
	for giant in giants:
		if giant.standing() and cat.body.height < Giant.TALL * 0.4 \
				and cat.body.position.distance_to(giant.body.position) <= giant.body.radius + cat.body.radius:
			over.append(giant)
	return over


## A riposte: a hit dodged as it landed, answered at once against everything around her.
func riposte(cat: Cat, damage: float) -> void:
	events.append({"position": cat.body.position, "height": 0.2, "direction": cat.facing, "killed": false, "by": "strike_back", "giant": false, "kind": "cat"})
	for creature: Creature in creatures.duplicate():
		var apart := creature.body.position - cat.body.position
		if apart.length() <= Cat.RIPOSTE_REACH + creature.body.radius:
			strike(creature, damage, apart.normalized(), 2.0, 1.0, "riposte", cat)
	for giant in giants:
		var apart := giant.body.position - cat.body.position
		if giant.standing() and apart.length() <= Cat.RIPOSTE_REACH + giant.body.radius:
			strike(giant, damage, apart.normalized(), 0.0, 0.0, "riposte", cat)
	_strike_machines(cat.body.position, Cat.RIPOSTE_REACH, damage, "riposte", cat)


## A pounce comes down: what's under her takes it, and what's around is thrown.
func land_pounce(cat: Cat, damage: float) -> void:
	events.append({"position": cat.body.position, "height": 0.0, "direction": cat.facing, "killed": false, "by": "landing", "giant": false, "kind": "cat"})
	for creature: Creature in creatures.duplicate():
		var apart := creature.body.position - cat.body.position
		if apart.length() <= Cat.POUNCE_RADIUS + creature.body.radius:
			strike(creature, damage, apart.normalized() if apart.length() > 0.001 else cat.facing, 1.6, 1.2, "pounce", cat)
	for giant in giants:
		var apart := giant.body.position - cat.body.position
		if giant.standing() and apart.length() <= Cat.POUNCE_RADIUS + giant.body.radius:
			strike(giant, damage, cat.facing, 0.0, 0.0, "pounce", cat)
	_strike_machines(cat.body.position, Cat.POUNCE_RADIUS, damage, "pounce", cat)


## Whether two bodies overlap, along the ground and in height, with a little give.
func _touching(a: Body, b: Body, give: float) -> bool:
	return a.position.distance_to(b.position) <= a.radius + b.radius + give \
			and a.height <= b.height + b.tall and b.height <= a.height + a.tall


## A felled giant hits the ground along his length: everything in that strip is crushed.
func land(giant: Giant) -> void:
	var feet := giant.body.position
	var head := feet + giant.fall_direction * Giant.TALL
	for creature in creatures.duplicate():
		var closest := Geometry2D.get_closest_point_to_segment(creature.body.position, feet, head)
		if closest.distance_to(creature.body.position) <= Giant.FALLEN_WIDTH:
			strike(creature, 100.0, Vector2.ZERO, 0.0, 0.0, "fall")
	for cat in cats:
		var closest := Geometry2D.get_closest_point_to_segment(cat.body.position, feet, head)
		var apart := cat.body.position - closest
		if apart.length() <= Giant.FALLEN_WIDTH:
			cat.hurt(Giant.FALL_DAMAGE, (apart.normalized() if apart.length() > 0.001 else giant.fall_direction.orthogonal()) * Giant.SHOCK_KNOCK)
	events.append({"position": (feet + head) / 2.0, "height": 0.0, "direction": giant.fall_direction, "killed": false, "by": "fall", "giant": true})


## Which way something walking through a spot pushes it: toward +1 if it's on the left of the
## spot, -1 if on the right, 0 if nothing is that close. Grass and ferns bend to it.
func brushing(where: Vector2, reach: float) -> int:
	for cat in cats:
		if cat.body.position.distance_to(where) < reach + cat.body.radius and not cat.body.airborne():
			return 1 if cat.body.position.x < where.x else -1
	var cell := _cell_of(where)
	for x in range(cell.x - 1, cell.x + 2):
		for y in range(cell.y - 1, cell.y + 2):
			for creature: Creature in _grid.get(Vector2i(x, y), []):
				if creature.body.position.distance_to(where) < reach + creature.body.radius:
					return 1 if creature.body.position.x < where.x else -1
	return 0


func nearest_cat(where: Vector2) -> Cat:
	var nearest: Cat = null
	var nearest_distance := INF
	for cat in cats:
		if not cat.alive():
			continue
		var distance := where.distance_squared_to(cat.body.position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = cat
	return nearest


func _cell_of(where: Vector2) -> Vector2i:
	return Vector2i(floori(where.x / CELL), floori(where.y / CELL))


func _build_grid() -> void:
	_grid.clear()
	for creature in creatures:
		var cell := _cell_of(creature.body.position)
		if _grid.has(cell):
			_grid[cell].append(creature)
		else:
			_grid[cell] = [creature]


## Creatures on the ground can't stand in each other: overlapping pairs are pushed apart, half
## each. The grid keeps it to neighbors, so a big horde costs what its crowding costs.
func _separate() -> void:
	for creature in creatures:
		if creature.body.airborne():
			continue
		var cell := _cell_of(creature.body.position)
		# A dog is wider than a cell: it looks two round, a rat one.
		var span := 2 if creature.body.radius > CELL / 2.0 else 1
		for x in range(cell.x - span, cell.x + span + 1):
			for y in range(cell.y - span, cell.y + span + 1):
				for other: Creature in _grid.get(Vector2i(x, y), []):
					if other == creature or other.body.airborne():
						continue
					var apart := creature.body.position - other.body.position
					var reach := creature.body.radius + other.body.radius
					var distance := apart.length()
					if distance >= reach:
						continue
					var push := (apart / distance if distance > 0.0001 else Vector2.RIGHT) * (reach - distance) * 0.5
					creature.body.position += push
					other.body.position -= push


func _bite() -> void:
	for cat in cats:
		if not cat.alive():
			continue
		var cell := _cell_of(cat.body.position)
		# Two cells round: a dog is wider than a cell.
		for x in range(cell.x - 2, cell.x + 3):
			for y in range(cell.y - 2, cell.y + 3):
				for creature: Creature in _grid.get(Vector2i(x, y), []):
					var apart := cat.body.position - creature.body.position
					# It bites what it can reach: along the ground and up off it, on its feet or in
					# the middle of a lunge.
					if creature.bite_ready_in > 0.0 or (creature.body.airborne() and not creature.lunging()) \
							or apart.length() > cat.body.radius + creature.body.radius + 0.02 \
							or cat.body.height > creature.body.height + creature.body.tall \
							or creature.body.height > cat.body.height + Cat.TALL:
						continue
					creature.bite_ready_in = creature.stat("bite_interval")
					if cat.hurt(creature.stat("bite"), apart.normalized() * 0.6):
						events.append({"position": cat.body.position, "height": 0.15, "direction": apart.normalized(), "killed": false, "by": "bite", "giant": false, "kind": creature.kind})


func _fly_shots() -> void:
	var flying: Array[Shot] = []
	for shot in shots:
		shot.previous = shot.position
		shot.previous_height = shot.height
		if shot.falls:
			shot.vertical_speed -= Body.GRAVITY * STEP
		shot.position += shot.velocity * STEP
		shot.height += shot.vertical_speed * STEP
		shot.life -= STEP
		var hit := _first_hit(shot)
		if hit != null:
			if shot.blast > 0.0:
				blast(hit.body.position, shot.blast, shot.damage, shot.weapon.knock, shot.weapon.lift, shot.weapon.name, shot.shooter)
			else:
				_strike(hit, shot)
			shot.spent = true
		elif shot.height <= 0.0 or shot.life <= 0.0:
			if shot.blast > 0.0 and shot.height <= 0.0:
				blast(shot.position, shot.blast, shot.damage, shot.weapon.knock, shot.weapon.lift, shot.weapon.name, shot.shooter)
			shot.spent = true
		if not shot.spent:
			flying.append(shot)
	shots = flying


## The first creature along the path a round moved this step, at the height it passed.
func _first_hit(shot: Shot) -> Object:
	var from := shot.previous
	var to := shot.position
	# Widened by the widest creature, so a round grazing a dog's edge isn't missed.
	var lowest := _cell_of(Vector2(minf(from.x, to.x), minf(from.y, to.y)) - Vector2.ONE * (CELL + 0.25))
	var highest := _cell_of(Vector2(maxf(from.x, to.x), maxf(from.y, to.y)) + Vector2.ONE * (CELL + 0.25))
	var first: Object = null
	var first_along := INF
	for x in range(lowest.x, highest.x + 1):
		for y in range(lowest.y, highest.y + 1):
			for creature: Creature in _grid.get(Vector2i(x, y), []):
				if not creature.alive():
					continue
				var closest := Geometry2D.get_closest_point_to_segment(creature.body.position, from, to)
				if closest.distance_to(creature.body.position) > creature.body.radius:
					continue
				var along := from.distance_to(closest)
				var share := along / maxf(from.distance_to(to), 0.0001)
				var passing := lerpf(shot.previous_height, shot.height, share)
				if passing < creature.body.height or passing > creature.body.height + creature.body.tall:
					continue
				if along < first_along:
					first_along = along
					first = creature
	for giant in giants:
		if not giant.standing():
			continue
		var closest := Geometry2D.get_closest_point_to_segment(giant.body.position, from, to)
		if closest.distance_to(giant.body.position) > giant.body.radius:
			continue
		var along := from.distance_to(closest)
		var passing := lerpf(shot.previous_height, shot.height, along / maxf(from.distance_to(to), 0.0001))
		if passing >= 0.0 and passing <= Giant.TALL and along < first_along:
			first_along = along
			first = giant
	# A machine stops a round where the round meets its steel, its joint where that's open.
	for machine in machines:
		for part: Object in [machine.joint, machine]:
			if not part.alive() or (part == machine and not machine.standing()):
				continue
			var closest := Geometry2D.get_closest_point_to_segment(part.body.position, from, to)
			var inside: bool = machine.covers(closest) if part == machine else closest.distance_to(part.body.position) <= part.body.radius
			if not inside:
				continue
			var along := from.distance_to(closest)
			var passing := lerpf(shot.previous_height, shot.height, along / maxf(from.distance_to(to), 0.0001))
			if passing >= part.body.height - 0.1 and passing <= part.body.height + part.body.tall and along < first_along:
				first_along = along
				first = part
	return first


func _strike(creature: Object, shot: Shot) -> void:
	strike(creature, shot.damage, shot.velocity.normalized(), shot.weapon.knock, shot.weapon.lift, "round", shot.shooter)


## A hit on a creature, from a round or a blade: it's hurt, thrown, and falls if it's done for.
func strike(target: Object, damage: float, direction: Vector2, knock: float, lift: float, by: String, attacker: Cat = null) -> void:
	if not target.alive():
		return
	if target is Machine or target is Machine.Joint:
		var on_joint: bool = target is Machine.Joint
		var machine: Machine = target.machine if on_joint else target
		var through := machine.take(damage, on_joint)
		if attacker != null:
			attacker.heal(through * attacker.adrenaline)
		events.append({"position": target.body.position, "height": minf(0.6, target.body.height + 0.2), "direction": direction, "killed": not machine.alive(), "by": by, "giant": true, "kind": "joint" if on_joint else "machine"})
		if not machine.alive():
			kills += 1
			machines_broken += 1
			_gain_experience(machine.worth)
		return
	var dealt: float = minf(damage, target.health)
	if attacker != null:
		attacker.heal(dealt * attacker.adrenaline)
	if target is Giant:
		var giant: Giant = target
		giant.take(damage, direction)
		# A push is shared over his mass: a round that throws a rat barely moves him.
		giant.body.velocity += direction * knock / Giant.HEFT
		events.append({"position": giant.body.position, "height": minf(0.3, Giant.TALL), "direction": direction, "killed": not giant.alive(), "by": by, "giant": true})
		if not giant.alive():
			kills += 1
			giants_felled += 1
			_gain_experience(giant.worth)
		return
	var creature: Creature = target
	creature.health -= damage
	# A push is shared over its mass: a dog takes a hit a rat would fly from.
	var heft: float = creature.stat("heft")
	creature.body.push(direction * knock / heft, lift / heft)
	# The view drains these as it draws; headless, nothing does, so the oldest go.
	if events.size() >= 256:
		events.pop_front()
	events.append({
		"position": creature.body.position, "height": creature.body.height + creature.body.tall * 0.5,
		"direction": direction, "killed": not creature.alive(), "by": by, "giant": false, "kind": creature.kind,
	})
	if creature.alive():
		return
	kills += 1
	_gain_experience(creature.worth)
	creatures.erase(creature)
	# It falls where it was hit, and keeps the way the hit sent it.
	var body := creature.body
	body.restitution = 0.3
	body.push(Vector2.ZERO, 1.2)
	fallen.append(body)


func _crumble() -> void:
	while fallen.size() > MOST_FALLEN:
		fading.append({"body": fallen.pop_front(), "left": FADE_TIME})
	var lasting: Array[Dictionary] = []
	for remains in fading:
		remains.left -= STEP
		if remains.left > 0.0:
			lasting.append(remains)
	fading = lasting


## Experience needed to go from this level to the next.
static func experience_needed(at_level: int) -> int:
	return 4 + at_level * 3


func _gain_experience(amount: int) -> void:
	experience += amount
	while experience >= experience_needed(level):
		experience -= experience_needed(level)
		level += 1
		for cat in cats:
			var offer := Upgrades.offer(cat, random)
			# Never an empty card: with mastery there's always something, but if not, no card.
			if not offer.is_empty():
				cat.offers.append(offer)


## With no cat in the clearing (behind the title, say) the horde and the giants amble about: each
## picks somewhere and goes there, then somewhere else.
func _wander() -> void:
	if not cats.is_empty():
		return
	for creature in creatures:
		if not creature.wander_to.is_finite() or creature.body.position.distance_to(creature.wander_to) < 0.4:
			creature.wander_to = Vector2(random.randf_range(1.0, SIZE.x - 1.0), random.randf_range(1.0, SIZE.y - 1.0))
	for giant in giants:
		if not giant.wander_to.is_finite() or giant.body.position.distance_to(giant.wander_to) < 1.0:
			giant.wander_to = Vector2(random.randf_range(3.0, SIZE.x - 3.0), random.randf_range(3.0, SIZE.y - 3.0))


func _keep_inside(body: Body) -> void:
	var inside := body.position.clamp(Vector2.ONE * body.radius, SIZE - Vector2.ONE * body.radius)
	if inside.x != body.position.x:
		body.velocity.x = 0.0
	if inside.y != body.position.y:
		body.velocity.y = 0.0
	body.position = inside


## The horde comes out of the jungle all around the clearing, and now and then, a giant.
func _spawn() -> void:
	if not spawning:
		return
	_since_giant += STEP
	if _since_giant >= GIANT_INTERVAL and giants.filter(func(giant: Giant) -> bool: return giant.standing()).size() < MOST_GIANTS:
		_since_giant = 0.0
		_giants_sent += 1
		var chainsaw := time >= CHAINSAW_FROM and _giants_sent % CHAINSAW_EVERY == 0
		add_giant(edge_point(), "chainsaw" if chainsaw else "worker")
	_since_machine += STEP
	if _since_machine >= MACHINE_INTERVAL and not machines.any(func(machine: Machine) -> bool: return machine.standing()):
		_since_machine = 0.0
		# It drives in out of the jungle, facing the clearing.
		var gate := edge_point()
		add_machine(gate.clamp(Vector2.ONE * 1.6, SIZE - Vector2.ONE * 1.6), (SIZE / 2.0 - gate).angle())
	_since_dogs += STEP
	if _since_dogs >= DOG_INTERVAL:
		_since_dogs = 0.0
		var dogs := creatures.filter(func(creature: Creature) -> bool: return creature.kind == "dog").size()
		# A pack comes out of the jungle together.
		var gate := edge_point()
		for index in mini(DOG_PACK, MOST_DOGS - dogs):
			add_creature((gate + Vector2(random.randf_range(-0.6, 0.6), random.randf_range(-0.6, 0.6))).clamp(Vector2.ONE * 0.3, SIZE - Vector2.ONE * 0.3), "dog")
	if creatures.size() >= MOST_CREATURES:
		return
	_since_spawn += STEP
	var interval := 1.0 / (SPAWN_RATE + SPAWN_GROWTH * time)
	while _since_spawn >= interval and creatures.size() < MOST_CREATURES:
		_since_spawn -= interval
		add_creature(edge_point())


## A random point just inside the jungle's edge.
func edge_point() -> Vector2:
	var along := random.randf() * 2.0 * (SIZE.x + SIZE.y)
	if along < SIZE.x:
		return Vector2(along, 0.2)
	along -= SIZE.x
	if along < SIZE.y:
		return Vector2(SIZE.x - 0.2, along)
	along -= SIZE.y
	if along < SIZE.x:
		return Vector2(along, SIZE.y - 0.2)
	return Vector2(0.2, along - SIZE.x)
