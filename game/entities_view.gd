class_name EntitiesView
extends Node2D
## Everything standing on the ground: the cats, the horde and the fallen, drawn back to front
## with a shadow under each, so height above the ground reads at a glance. Rounds in the air
## draw as short tracers.

## Muzzle flashes last this long, in seconds.
const FLASH_TIME := 0.05
## Ground covered by one full walk cycle, in meters: the frames step with the feet, so they
## never slide, and a body knocked through the air doesn't run.
const CAT_STRIDE := 0.42
const RAT_STRIDE := 0.24
const DOG_STRIDE := 0.6
const GIANT_STRIDE := 1.4

var arena: Arena
## Blood, or with it off, the same hits throwing up dust and fur instead.
var blood := true
## How bright each cat's muzzle is right now, 0 to 1, and the rounds counted at the last frame.
var flash := {}
var _rounds_seen := {}
## Droplets in the air, and the stains they leave: real particles, landing where they fall.
var _droplets: Array[Dictionary] = []
## Hits handed over since the last frame, to throw blood or dust for.
var _pending: Array[Dictionary] = []
var _stains: Array[Dictionary] = []
const MOST_STAINS := 900
const STAIN_DRIES := 15.0
const STAIN_LASTS := 45.0
var _dust: Array[Dictionary] = []
## How far each cat and creature has walked, and where it was last frame.
var _walked := {}
var _last := {}


## Hits from the simulation's steps since the last frame.
func take_events(events: Array[Dictionary]) -> void:
	_pending.append_array(events)


func _process(delta: float) -> void:
	for cat in arena.cats:
		var fired := 0
		for weapon in cat.weapons:
			fired += weapon.rounds_fired
		if fired != _rounds_seen.get(cat, 0):
			flash[cat] = 1.0
		_rounds_seen[cat] = fired
		flash[cat] = maxf(flash.get(cat, 0.0) - delta / FLASH_TIME, 0.0)
		if cat.dodging_for > 0.0:
			_kick_dust(cat.body)
	_settle_dust(delta)
	_bleed(delta)
	_pace()
	queue_redraw()


## Counts the ground each walker has covered on its feet.
func _pace() -> void:
	var walked := {}
	var last := {}
	var walkers: Array = arena.cats + arena.creatures + arena.giants
	for walker: Object in walkers:
		var body: Body = walker.body
		var moved: float = body.position.distance_to(_last.get(walker, body.position))
		walked[walker] = _walked.get(walker, 0.0) + (0.0 if body.airborne() else moved)
		last[walker] = body.position
	_walked = walked
	_last = last


func _frame(walker: Object, stride: float) -> int:
	if walker.body.velocity.length() < 0.1:
		return 0
	return int(_walked.get(walker, 0.0) / stride * 4.0) % 4


func _draw() -> void:
	var standing: Array[Array] = []
	for creature in arena.creatures:
		standing.append([creature.body.position.y, creature])
	for body in arena.fallen:
		standing.append([body.position.y, body])
	for cat in arena.cats:
		standing.append([cat.body.position.y, cat])
	for remains in arena.fading:
		standing.append([remains.body.position.y, remains])
	for giant in arena.giants:
		standing.append([giant.body.position.y, giant])
	standing.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for stain in _stains:
		draw_rect(Rect2(World.to_screen(stain.position), Vector2.ONE), Palette.BLOOD if stain.age < STAIN_DRIES else Palette.BLOOD_DRY)
	for entry in standing:
		_draw_shadow(entry[1])
	for entry in standing:
		var thing: Variant = entry[1]
		if thing is Cat:
			_draw_cat(thing)
		elif thing is Giant:
			_draw_giant(thing)
		elif thing is Creature:
			if thing.kind == "dog":
				_draw_dog(thing.body, _frame(thing, DOG_STRIDE), false, thing.state == Creature.State.CROUCHING)
			else:
				_draw_rat(thing.body, _frame(thing, RAT_STRIDE), false)
		elif thing is Body:
			if thing.kind == "dog":
				_draw_dog(thing, 1, true, false)
			else:
				_draw_rat(thing, 0, true)
		else:
			_draw_remains(entry[1])
	for speck in _dust:
		draw_rect(Rect2(World.to_screen(speck.position, speck.height), Vector2.ONE), Palette.SMOKE)
	for droplet in _droplets:
		draw_rect(Rect2(World.to_screen(droplet.position, droplet.height), Vector2.ONE), droplet.color)
	for shot in arena.shots:
		draw_line(World.to_screen(shot.previous, shot.previous_height), World.to_screen(shot.position, shot.height), Palette.SPARK)


func _draw_shadow(thing: Variant) -> void:
	if thing is Dictionary:
		return
	if thing is Giant:
		_draw_giant_shadow(thing)
		return
	var body: Body = thing.body if thing is Cat or thing is Creature else thing
	# A pixel ellipse on the ground, narrower the higher the body is.
	var width := roundi(body.radius * 2.0 * World.PIXELS_PER_METER * clampf(1.0 - body.height, 0.5, 1.0))
	var center := World.to_screen(body.position)
	draw_rect(Rect2(center + Vector2(-width / 2 + 1, -1), Vector2(maxi(width - 2, 1), 3)), Palette.GROUND_SHADOW)
	draw_rect(Rect2(center + Vector2(-width / 2, 0), Vector2(width, 1)), Palette.GROUND_SHADOW)


func _draw_rat(body: Body, frame: int, fallen: bool) -> void:
	var facing_left := body.velocity.x < 0.0
	# The fallen lie belly up.
	var texture := Sprites.lit(Sprites.RAT_STRIDES[frame], facing_left, fallen)
	draw_texture(texture, _rat_corner(body, texture, facing_left) - Vector2(0, 0 if fallen else Sprites.RAT_LIFT[frame]))


## A dog: galloping, or bunched low before a lunge, or fallen on its back.
func _draw_dog(body: Body, frame: int, fallen: bool, crouching: bool) -> void:
	var facing_left := body.velocity.x < 0.0
	var art := Sprites.dog_art(2 if crouching else frame)
	var texture := Sprites.lit(art, facing_left, fallen)
	var feet := Sprites.DOG_FEET
	if facing_left:
		feet.x = texture.get_width() - 1 - feet.x
	var corner := World.to_screen(body.position, body.height) - feet
	if crouching:
		# Down on its haunches: the warning before the leap.
		corner.y += 4
	elif not fallen:
		corner.y -= Sprites.DOG_LIFT[frame]
	draw_texture(texture, corner)


## Remains crumbling away, a few more pixels gone each stage.
func _draw_remains(remains: Dictionary) -> void:
	var body: Body = remains.body
	var stage := clampi(int((1.0 - remains.left / Arena.FADE_TIME) * Sprites.STAGES), 0, Sprites.STAGES - 1) + 1
	var art: String = Sprites.dog_art(1) if body.kind == "dog" else Sprites.RAT_STRIDES[0]
	var texture := Sprites.crumbled(art, stage, false, true)
	draw_texture(texture, _rat_corner(body, texture, false))


func _rat_corner(body: Body, texture: Texture2D, facing_left: bool) -> Vector2:
	var feet := Sprites.RAT_FEET
	if facing_left:
		feet.x = texture.get_width() - 1 - feet.x
	return World.to_screen(body.position, body.height) - feet


func _draw_cat(cat: Cat) -> void:
	var feet := World.to_screen(cat.body.position, cat.body.height)
	var top_left := feet - Sprites.CAT_FEET
	if cat.dodging_for > 0.0:
		# Tucked into the roll.
		top_left.y += 3.0
	var facing := Sprites.cat_view(cat.facing)
	var view: String = facing[0]
	var flip: bool = facing[1]
	var frame := _frame(cat, CAT_STRIDE)
	var arms := _pose_arms(cat, view, flip, frame, top_left)
	for arm in arms:
		if arm.behind:
			_draw_arm(arm)
	draw_texture(Sprites.lit(Sprites.cat_body_art(view, frame, cat.gear.get("feet", "") == "boots"), flip), top_left)
	# Everything above the waist leans with the body as she walks.
	var leaning := top_left + Vector2(Sprites.lean(view, frame), 0)
	if cat.gear.get("body", "") == "vest":
		draw_texture(Sprites.lit(Sprites.VESTS[view], flip), leaning)
	for slot in ["neck", "waist", "eyes"]:
		var item: String = cat.gear.get(slot, "")
		if Sprites.WORN.has(item):
			draw_texture(Sprites.lit(Sprites.WORN[item][view], flip), leaning)
	var hat: String = cat.gear.get("head", "")
	if Sprites.HATS.has(hat):
		draw_texture(Sprites.lit(Sprites.HATS[hat]), leaning + Sprites.cat_anchor(view, flip, "head"))
	for arm in arms:
		if not arm.behind:
			_draw_arm(arm)


## Where each arm reaches, and what it holds. A paw with a gun reaches toward what she's aiming at
## and jolts back as it fires; one with a blade follows the blade round its swing; an empty one
## swings against the stride.
func _pose_arms(cat: Cat, view: String, flip: bool, frame: int, top_left: Vector2) -> Array[Dictionary]:
	var leading := "left" if cat.aim.x < 0.0 else "right"
	if view == "side":
		leading = "right"
	var trailing := "left" if leading == "right" else "right"
	var arms: Array[Dictionary] = []
	for side in [leading, trailing]:
		var index := 0 if side == leading else 1
		var shoulder: Vector2 = top_left + Sprites.shoulder(view, flip, side, frame)
		var arm := {"shoulder": shoulder, "weapon": null, "drawing": {}, "behind": view == "side" and side == "left",
			"paw": Palette.LEATHER_LIGHT if cat.gear.get("paws", "") == "gloves" else Palette.CREAM}
		if index < cat.weapons.size():
			var weapon: Weapon = cat.weapons[index]
			var pointing := Vector2.from_angle(weapon.blade_angle) if weapon.swinging() else cat.aim
			var reach := Sprites.ARM_REACH
			if weapon.kind == Weapon.Kind.RANGED and flash.get(cat, 0.0) > 0.5:
				reach -= 2.0
			elif weapon.kind == Weapon.Kind.MELEE and not weapon.swinging():
				reach = 3.0
			arm.at = (shoulder + pointing * reach).round()
			arm.weapon = weapon
			arm.drawing = Sprites.gun_toward(weapon.name, pointing)
			# Reaching up and away, the arm and what it holds are behind her.
			arm.behind = arm.behind or pointing.y < -0.35
		else:
			var swing: int = [0, 1, 0, -1][frame] * (1 if side == "left" else -1)
			arm.at = shoulder + Vector2(swing, 4)
		arms.append(arm)
	return arms


func _draw_arm(arm: Dictionary) -> void:
	var points := _limb(arm.shoulder, arm.at)
	for point in points:
		draw_rect(Rect2(point - Vector2.ONE, Vector2(3, 3)), Palette.OUTLINE)
	for point in points:
		draw_rect(Rect2(point, Vector2.ONE), Palette.FUR)
	draw_rect(Rect2(arm.at, Vector2.ONE), arm.paw)
	var weapon: Weapon = arm.weapon
	if weapon == null:
		return
	var drawing: Dictionary = arm.drawing
	var at: Vector2 = arm.at - drawing.grip
	draw_texture(drawing.texture, at)
	# The paw closes over the grip.
	draw_rect(Rect2(arm.at, Vector2.ONE), arm.paw)
	if weapon.swinging():
		_draw_smear(weapon, arm.at)
	elif weapon.kind == Weapon.Kind.RANGED and flash.get(arena.cats[0], 0.0) > 0.0:
		draw_rect(Rect2(at + drawing.muzzle - Vector2.ONE, Vector2(3, 3)), Palette.SPARK)


## The pixels of a limb from one point to another, one per step along it.
func _limb(from: Vector2, to: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var steps := maxi(int(from.distance_to(to)), 1)
	for step in steps + 1:
		points.append(from.lerp(to, float(step) / steps).round())
	return points


## The blade's path through the air, the last stretch of it: bright at the edge, fading back
## along the arc in palette steps.
func _draw_smear(weapon: Weapon, paw: Vector2) -> void:
	var radius := weapon.reach * World.PIXELS_PER_METER * 0.8
	var trail := 0.9
	var step := 0.07
	var traveled := 0.0
	while traveled < trail:
		var angle := weapon.blade_angle - weapon.swing_direction * traveled
		if weapon.swing_direction * (angle - weapon.swing_start) < 0.0:
			break
		var color := Palette.STEEL_LIGHT if traveled < 0.3 else (Palette.STEEL if traveled < 0.6 else Palette.SMOKE)
		draw_rect(Rect2((paw + Vector2.from_angle(angle) * radius).round(), Vector2.ONE), color)
		traveled += step


## Each hit throws droplets out along it and up. They fall under gravity and stain the ground
## where they land; stains dry, and in time are gone. With blood off, the same hits throw up
## dust and fur, which leave nothing.
func _bleed(delta: float) -> void:
	for event in _pending:
		if event.by == "lunge":
			continue
		if event.by == "stomp" or event.by == "fall":
			# The ground thrown up: dust and clods, no blood.
			for index in 18:
				_droplets.append({
					"position": event.position, "height": 0.02, "rise": randf_range(0.8, 2.0),
					"velocity": Vector2.from_angle(randf() * TAU) * randf_range(0.5, 2.0),
					"color": Palette.SMOKE if index % 3 else Palette.MUD_LIGHT, "stains": false,
				})
			continue
		var count := 6 if event.killed else 3
		for index in count:
			var spray: Vector2 = event.direction * randf_range(0.4, 1.4) + Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
			_droplets.append({
				"position": event.position, "height": event.height, "velocity": spray, "rise": randf_range(0.4, 1.6),
				"color": Palette.BLOOD if blood else (Palette.RAT_LIGHT if index % 2 == 0 else Palette.SMOKE),
				"stains": blood,
			})
	_pending.clear()
	var flying: Array[Dictionary] = []
	for droplet in _droplets:
		droplet.rise -= Body.GRAVITY * delta
		droplet.height += droplet.rise * delta
		droplet.position += droplet.velocity * delta
		if droplet.height > 0.0:
			flying.append(droplet)
		elif droplet.stains:
			_stains.append({"position": droplet.position, "age": 0.0})
	_droplets = flying
	var lasting: Array[Dictionary] = []
	for stain in _stains:
		stain.age += delta
		if stain.age < STAIN_LASTS:
			lasting.append(stain)
	_stains = lasting
	while _stains.size() > MOST_STAINS:
		_stains.pop_front()


func _kick_dust(body: Body) -> void:
	for index in 2:
		_dust.append({
			"position": body.position + Vector2(randf_range(-0.08, 0.08), randf_range(-0.03, 0.03)),
			"height": 0.01, "velocity": Vector2(randf_range(-0.4, 0.4), randf_range(-0.2, 0.2)),
			"rise": randf_range(0.3, 0.8), "life": randf_range(0.25, 0.5),
		})


## Dust from a roll is real particles: thrown up, falling back, gone when it settles.
func _settle_dust(delta: float) -> void:
	var settling: Array[Dictionary] = []
	for speck in _dust:
		speck.life -= delta
		speck.rise -= Body.GRAVITY * 0.3 * delta
		speck.height = maxf(speck.height + speck.rise * delta, 0.0)
		speck.position += speck.velocity * delta
		if speck.life > 0.0:
			settling.append(speck)
	_dust = settling


## A giant's shadow, stretched along the ground as he falls; and while he winds up a stomp, the
## boot's shadow where it will land, rimmed in hi-vis: the warning.
func _draw_giant_shadow(giant: Giant) -> void:
	var feet := World.to_screen(giant.body.position)
	var lean := giant.fall_direction * Giant.TALL * sin(giant.fall_angle)
	var end := World.to_screen(giant.body.position + lean)
	_thick(feet, end, 8, Palette.GROUND_SHADOW, 0)
	draw_rect(Rect2(feet + Vector2(-11, -2), Vector2(22, 4)), Palette.GROUND_SHADOW)
	if giant.state == Giant.State.WINDING:
		var boot := World.to_screen(giant.foot)
		var size := Vector2(14, 6) * (1.0 - giant.foot_height / Giant.BOOT_HEIGHT * 0.3)
		draw_rect(Rect2(boot - size / 2.0 - Vector2.ONE, size + Vector2(2, 2)), Palette.HI_VIS, false, 1.0)
		draw_rect(Rect2(boot - size / 2.0, size), Palette.GROUND_SHADOW)


## A logging worker, built as a rig of joints in three dimensions (across his body, up it, and
## forward along the way he faces) and projected the way the scene is. The same rig shows his
## front walking toward the viewer, his back walking away, his side walking across, and
## foreshortens as he topples. Parts draw far to near, so the nearer leg covers the further.
## Legs stride with the ground he covers; arms swing against them.
func _draw_giant(giant: Giant) -> void:
	var phase: float = _walked.get(giant, 0.0) / GIANT_STRIDE * TAU
	var walking := giant.body.velocity.length() > 0.05
	var stride := sin(phase) * 0.32 if walking else 0.0
	var lift := maxf(cos(phase), 0.0) * 0.06 if walking else 0.0
	var dissolve := clampf((giant.fallen_for - (Arena.FELLED_LASTS - 1.5)) / 1.5, 0.0, 1.0)
	var hip := 0.92
	var shoulder := 1.42
	# Each foot: [across, up, forward]. The right boot comes up for a stomp.
	var right_foot := [0.12, lift, stride]
	var left_foot := [-0.12, maxf(-cos(phase), 0.0) * 0.06 if walking else 0.0, -stride]
	if giant.state == Giant.State.WINDING:
		right_foot = [0.12, giant.foot_height, 0.4]
	var parts: Array[Dictionary] = []
	for leg: Array in [[0.12, right_foot, Palette.CLOTH], [-0.12, left_foot, Palette.CLOTH_SHADOW]]:
		var foot: Array = leg[1]
		parts.append(_part(giant, [leg[0], hip, 0.0], foot, 6, leg[2]))
		parts.append(_part(giant, foot, [foot[0], foot[1], foot[2] + 0.14], 5, Palette.LEATHER_LIGHT if leg[0] > 0.0 else Palette.LEATHER))
	for arm: Array in [[0.25, -1.0, Palette.SKIN], [-0.25, 1.0, Palette.SKIN_SHADOW]]:
		parts.append(_part(giant, [arm[0], shoulder, 0.0], [arm[0] * 1.1, 0.86, stride * 0.6 * arm[1]], 4, arm[2]))
	parts.append(_part(giant, [0.0, hip, 0.0], [0.0, shoulder, 0.0], 14, Palette.HI_VIS))
	# The reflective band across the vest, the head, and the hard hat over it.
	parts.append(_part(giant, [0.0, 1.15, 0.0], [0.0, 1.15, 0.0], 14, Palette.STEEL_LIGHT, 0.01, 2))
	parts.append(_part(giant, [0.0, 1.5, 0.02], [0.0, 1.62, 0.02], 9, Palette.SKIN, 0.02))
	parts.append(_part(giant, [0.0, 1.66, 0.02], [0.0, 1.7, 0.02], 11, Palette.BRASS_LIGHT, 0.03, 5))
	parts.append(_part(giant, [0.0, 1.64, -0.06], [0.0, 1.64, 0.16], 3, Palette.BRASS, 0.04))
	parts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.depth < b.depth)
	for part in parts:
		_thick(part.from, part.to, part.width, part.color, dissolve, part.tall)
	# Seen from the front, his eyes under the brim.
	if giant.facing.y > 0.35 and giant.standing():
		for across in [-0.04, 0.04]:
			draw_rect(Rect2(_giant_point(giant, across, 1.6, 0.09), Vector2.ONE), Palette.OUTLINE)
	if giant.standing() and giant.health < Giant.MOST_HEALTH:
		var top := _giant_point(giant, 0.0, 1.88, 0.0)
		var share := giant.health / Giant.MOST_HEALTH
		draw_rect(Rect2(top + Vector2(-12, 0), Vector2(24, 3)), Palette.GRAPHITE)
		draw_rect(Rect2(top + Vector2(-11, 1), Vector2(roundf(22 * share), 1)), Palette.HI_VIS)


## A limb of the rig between two joints, with how near the viewer it is: further down the ground
## is nearer.
func _part(giant: Giant, from: Array, to: Array, width: int, color: Color, bias := 0.0, tall := 0) -> Dictionary:
	var middle := (_giant_ground(giant, from[0], from[1], from[2]) + _giant_ground(giant, to[0], to[1], to[2])) / 2.0
	return {
		"from": _giant_point(giant, from[0], from[1], from[2]), "to": _giant_point(giant, to[0], to[1], to[2]),
		"width": width, "tall": tall if tall > 0 else width, "color": color, "depth": middle.y + bias,
	}


## Where a joint stands over the ground: across his body, forward along his facing, and tipped
## over by his fall.
func _giant_ground(giant: Giant, across: float, up: float, forward: float) -> Vector2:
	var side := giant.facing.orthogonal()
	if side.y < 0.0:
		side = -side
	return giant.body.position + giant.facing * forward + side * across + giant.fall_direction * up * sin(giant.fall_angle)


func _giant_point(giant: Giant, across: float, up: float, forward: float) -> Vector2:
	return World.to_screen(_giant_ground(giant, across, up, forward), up * cos(giant.fall_angle))


## A thick limb from one point to another, outlined. Remains dissolving drop pixels in a fixed
## scatter as the stage goes from 0 to 1.
func _thick(from: Vector2, to: Vector2, width: int, color: Color, dissolve: float, tall := 0) -> void:
	var points := _limb(from, to)
	var size := Vector2(width, tall if tall > 0 else width)
	var half := size / 2.0
	for point in points:
		draw_rect(Rect2((point - half - Vector2.ONE).round(), size + Vector2(2, 2)), Palette.OUTLINE)
	for point in points:
		if dissolve > 0.0 and float(int(point.x * 7 + point.y * 13) % 17) / 17.0 < dissolve:
			continue
		draw_rect(Rect2((point - half).round(), size), color)
