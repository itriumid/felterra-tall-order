class_name ObstacleArt
extends RefCounted
## What stands in an area, drawn from its shape: trees, stumps, bushes and rocks, a fallen trunk,
## stacks of logs with their cut ends to us, the company's cabins, crates, its hangar and fuel
## tank. Drawn once each, as pictures. No outlines: it's the environment. Lit from the top left,
## each casting its shadow down to the right.

## How tall a tree's trunk is drawn, in meters, up to where its crown sits.
const TREE_HEIGHT := 2.5
const PIXELS := World.PIXELS_PER_METER


## An obstacle's picture, and where its top left goes on screen.
static func picture(obstacle: Obstacle, seed_value: int) -> Dictionary:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	if obstacle.is_round():
		var radius := roundi(obstacle.radius * PIXELS)
		var foot := World.to_screen(obstacle.center)
		match obstacle.kind:
			"tree":
				var width := clampi(roundi(obstacle.radius * 20.0), 8, 18)
				var height := roundi(TREE_HEIGHT * PIXELS)
				var trunk := EnvironmentArt.trunk(height, width, random.randi())
				return {"image": trunk, "at": (foot + Vector2(0, 3) - Vector2(trunk.get_width() / 2, height)).round()}
			"bush":
				return _bush(radius, foot, random)
			"rock":
				return _rock(radius, roundi(obstacle.tall * PIXELS), foot, random)
			"stump":
				return _cylinder(radius, roundi(obstacle.tall * PIXELS), foot, [Palette.BARK_LIGHT, Palette.BARK, Palette.MUD_DARK], [Palette.BARK_LIGHT, Palette.DRY_GRASS, Palette.MUD_LIGHT], random)
			"tank":
				return _cylinder(radius, roundi(obstacle.tall * PIXELS), foot, [Palette.STEEL_LIGHT, Palette.STEEL, Palette.STEEL_DARK], [Palette.STEEL, Palette.STEEL_LIGHT, Palette.STEEL_LIGHT], random, true)
	return _box(obstacle, random)


## A box on the ground, seen from the front and above: its top, its front face, its shadow.
static func _box(obstacle: Obstacle, random: RandomNumberGenerator) -> Dictionary:
	var tall := roundi(obstacle.tall * PIXELS)
	var width := roundi(obstacle.rect.size.x * PIXELS)
	var deep := roundi(obstacle.rect.size.y * PIXELS)
	var shade := clampi(tall / 4, 3, 14)
	var roof := 3 if obstacle.kind in ["cabin", "hangar"] else 0
	var picture := Image.create_empty(width + shade + roof * 2, deep + tall + roof + 2, false, Image.FORMAT_RGBA8)
	# Its shadow, down to the right of it: a dither, so the ground shows through.
	_dither(picture, Rect2i(roof + width, roof + tall / 2 + 2, shade, deep + tall / 2 - 2))
	_dither(picture, Rect2i(roof + 2, roof + deep + tall, width + shade - 2, 2))
	var top := Rect2i(roof, roof, width, deep)
	var front := Rect2i(roof, roof + deep, width, tall)
	match obstacle.kind:
		"trunk": _fallen_trunk(picture, top, front, random)
		"log_stack": _log_stack(picture, top, front, random)
		"cabin": _cabin(picture, top, front, roof, random)
		"crates": _crates(picture, top, front, random)
		"hangar": _hangar(picture, top, front, roof)
	var corner := World.to_screen(obstacle.rect.position) - Vector2(roof, tall + roof)
	return {"image": picture, "at": corner.round()}


## A trunk lying where it fell: bark along it, rounded light to dark, its cut end catching the light.
static func _fallen_trunk(picture: Image, top: Rect2i, front: Rect2i, random: RandomNumberGenerator) -> void:
	# Round, lying down: seen from the front and above, a band lit along its top, falling into
	# shade underneath, its ends rounded off.
	var all := top.merge(front)
	var half := all.size.y * 0.5
	for y in all.size.y:
		var across := (y - half) / half
		var inset := roundi(half * (1.0 - sqrt(maxf(1.0 - across * across, 0.0))) * 0.6)
		for x in range(all.position.x + inset, all.end.x - inset):
			var color := Palette.BARK_LIGHT if across < -0.35 else (Palette.BARK if across < 0.45 else Palette.MUD_DARK)
			# Bark runs in streaks along it, and moss grows on its top.
			if (y * 7 + int(x / 5.0) * 3) % 8 == 0:
				color = Palette.BARK if color == Palette.BARK_LIGHT else Palette.MUD_DARK
			if across < -0.5 and random.randf() < 0.12:
				color = Palette.MOSS if random.randf() < 0.7 else Palette.LEAF
			picture.set_pixel(x, all.position.y + y, color)
	for crack in all.size.x / 8:
		var at := Vector2i(all.position.x + random.randi_range(6, all.size.x - 10), all.position.y + random.randi_range(2, all.size.y - 3))
		picture.fill_rect(Rect2i(at, Vector2i(random.randi_range(4, 8), 1)), Palette.MUD_DARK)
	# The cut end, on the left, toward the light: rings.
	var end := Vector2(all.position.x + 3, all.position.y + half)
	_ellipse(picture, end, Vector2(3, half - 1), Palette.BARK)
	_ellipse(picture, end, Vector2(2, half - 3), Palette.DRY_GRASS)
	_ellipse(picture, end, Vector2(1, maxf(half / 3.0, 1.0)), Palette.MUD_LIGHT)


## Logs stacked with their cut ends to us: rows of rings on the front, their lengths on top.
static func _log_stack(picture: Image, top: Rect2i, front: Rect2i, random: RandomNumberGenerator) -> void:
	# On top, the logs' lengths running away from us, each lit down its left.
	for x in top.size.x:
		var color := Palette.BARK_LIGHT if x % 9 < 3 else (Palette.BARK if x % 9 < 8 else Palette.MUD_DARK)
		picture.fill_rect(Rect2i(top.position.x + x, top.position.y, 1, top.size.y), color)
	for knot in top.size.x / 4:
		picture.set_pixel(top.position.x + random.randi_range(0, top.size.x - 1), top.position.y + random.randi_range(0, top.size.y - 1), Palette.MUD_DARK)
	picture.fill_rect(front, Palette.MUD_DARK)
	var size := 9
	var row := 0
	var y := front.end.y - size
	while y >= front.position.y - 2:
		var shift := (size / 2) if row % 2 == 1 else 0
		var x := front.position.x + shift
		while x + size <= front.end.x:
			_log_end(picture, Vector2i(x, y), size, random)
			x += size
		y -= size - 1
		row += 1


static func _log_end(picture: Image, corner: Vector2i, size: int, random: RandomNumberGenerator) -> void:
	var center := Vector2(corner) + Vector2.ONE * (size - 1) * 0.5
	for y in size:
		for x in size:
			var apart := (Vector2(corner + Vector2i(x, y)) - center).length() / (size * 0.5)
			if apart > 1.0 or corner.y + y < 0 or corner.y + y >= picture.get_height():
				continue
			var color := Palette.BARK if apart > 0.75 else (Palette.DRY_GRASS if apart > 0.3 else Palette.MUD_LIGHT)
			# The top left of each catches the light.
			if apart > 0.75 and x + y < size - 1:
				color = Palette.BARK_LIGHT
			picture.set_pixel(corner.x + x, corner.y + y, color)
	if random.randf() < 0.3:
		picture.set_pixel(corner.x + size / 2 + 1, corner.y + size / 2, Palette.BARK)


## A company cabin: a steel roof over the top, corrugated walls in front, a door, a window lit from
## inside, and the company's orange stripe.
static func _cabin(picture: Image, top: Rect2i, front: Rect2i, roof: int, random: RandomNumberGenerator) -> void:
	picture.fill_rect(front, Palette.STEEL_LIGHT)
	for x in range(front.position.x + 2, front.end.x, 4):
		picture.fill_rect(Rect2i(x, front.position.y, 1, front.size.y), Palette.STEEL)
	picture.fill_rect(Rect2i(front.end.x - 4, front.position.y, 4, front.size.y), Palette.STEEL)
	picture.fill_rect(Rect2i(front.position.x, front.position.y + 14, front.size.x, 3), Palette.HI_VIS)
	var door := Rect2i(front.position.x + front.size.x / 2 - 9, front.end.y - 34, 18, 34)
	picture.fill_rect(door, Palette.STEEL_DARK)
	picture.fill_rect(Rect2i(door.position.x + 13, door.position.y + 17, 2, 2), Palette.BRASS)
	for side in [-1, 1]:
		var window := Rect2i(front.position.x + front.size.x / 2 + side * 46 - 12, front.position.y + 24, 24, 16)
		if window.position.x < front.position.x + 4 or window.end.x > front.end.x - 6:
			continue
		picture.fill_rect(window, Palette.STEEL_DARK)
		picture.fill_rect(window.grow(-2), Palette.SPARK if random.randf() < 0.6 else Palette.JUNGLE_DEEP)
		picture.fill_rect(Rect2i(window.position.x + window.size.x / 2, window.position.y, 1, window.size.y), Palette.STEEL_DARK)
	# The roof overhangs every way: steel sheet in ridges, rusting where it's lapped.
	var over := top.grow(roof)
	picture.fill_rect(over, Palette.STEEL_DARK)
	for x in range(over.position.x + 1, over.end.x, 4):
		picture.fill_rect(Rect2i(x, over.position.y, 1, over.size.y), Palette.STEEL)
	for y in range(over.position.y + 30, over.end.y - 4, 31):
		picture.fill_rect(Rect2i(over.position.x, y, over.size.x, 1), Palette.MUD_LIGHT)
	for rust in over.size.x / 3:
		picture.fill_rect(Rect2i(over.position.x + random.randi_range(0, over.size.x - 3), over.position.y + random.randi_range(0, over.size.y - 2), random.randi_range(1, 3), 1), Palette.MUD_LIGHT)
	picture.fill_rect(Rect2i(over.position.x, over.position.y, over.size.x, 1), Palette.STEEL)
	picture.fill_rect(Rect2i(over.position.x, over.end.y - 2, over.size.x, 2), Palette.MUD_DARK)


## Supply crates, stacked: planks, the steel bands round them, the company's stencil.
static func _crates(picture: Image, top: Rect2i, front: Rect2i, random: RandomNumberGenerator) -> void:
	picture.fill_rect(top, Palette.DRY_GRASS)
	picture.fill_rect(front, Palette.BARK_LIGHT)
	for y in range(front.position.y + 4, front.end.y, 5):
		picture.fill_rect(Rect2i(front.position.x, y, front.size.x, 1), Palette.BARK)
	for x in range(top.position.x + 6, top.end.x, 7):
		picture.fill_rect(Rect2i(x, top.position.y, 1, top.size.y), Palette.BARK_LIGHT)
	var crate := 32
	for x in range(front.position.x, front.end.x, crate):
		picture.fill_rect(Rect2i(x, front.position.y, 2, front.size.y), Palette.STEEL_DARK)
		picture.fill_rect(Rect2i(x, top.position.y, 2, top.size.y), Palette.STEEL)
		if x + 14 < front.end.x and random.randf() < 0.7:
			picture.fill_rect(Rect2i(x + 8, front.position.y + 12, 8, 6), Palette.HI_VIS)
	picture.fill_rect(Rect2i(front.end.x - 2, front.position.y, 2, front.size.y), Palette.STEEL_DARK)


## The hangar: a curved steel roof, ridged, over a wide door standing open on the dark inside.
static func _hangar(picture: Image, top: Rect2i, front: Rect2i, roof: int) -> void:
	var over := top.grow(roof)
	for y in over.size.y:
		var across := float(y) / over.size.y
		# The curve: lit near the top, falling into shade toward the front.
		var color := Palette.STEEL if across < 0.25 else (Palette.STEEL_LIGHT if across < 0.55 else (Palette.STEEL if across < 0.85 else Palette.STEEL_DARK))
		picture.fill_rect(Rect2i(over.position.x, over.position.y + y, over.size.x, 1), color)
	for x in range(over.position.x + 3, over.end.x, 8):
		picture.fill_rect(Rect2i(x, over.position.y, 1, over.size.y), Palette.STEEL_DARK)
	picture.fill_rect(front, Palette.STEEL)
	for x in range(front.position.x + 2, front.end.x, 4):
		picture.fill_rect(Rect2i(x, front.position.y, 1, front.size.y), Palette.STEEL_LIGHT)
	var door := Rect2i(front.position.x + front.size.x / 5, front.position.y + 18, front.size.x * 3 / 5, front.size.y - 18)
	picture.fill_rect(door, Palette.JUNGLE_DEEP)
	picture.fill_rect(Rect2i(door.position.x, door.position.y, door.size.x, 3), Palette.STEEL_DARK)
	picture.fill_rect(Rect2i(front.position.x, front.position.y + 8, front.size.x, 3), Palette.HI_VIS)


## A cylinder standing on the ground, lit from the left: a stump, a tank. Its top is seen from
## above as an ellipse.
static func _cylinder(radius: int, tall: int, foot: Vector2, side: Array, rings: Array, random: RandomNumberGenerator, banded := false) -> Dictionary:
	var squash := maxi(radius / 2, 2)
	var shade := mini(tall / 2, 20)
	var picture := Image.create_empty(radius * 2 + shade + 1, squash * 2 + tall + 3, false, Image.FORMAT_RGBA8)
	var middle := Vector2(radius, squash)
	_ellipse(picture, middle + Vector2(shade * 0.6, tall + 1), Vector2(radius, squash), Palette.GROUND_SHADOW, true)
	for x in radius * 2 + 1:
		var across := (x - radius) / float(radius)
		var dip := roundi(squash * sqrt(maxf(1.0 - across * across, 0.0)))
		var color: Color = side[0] if across < -0.4 else (side[1] if across < 0.5 else side[2])
		picture.fill_rect(Rect2i(x, squash, 1, tall + dip), color)
		if banded:
			picture.fill_rect(Rect2i(x, squash + tall / 3, 1, 3), Palette.HI_VIS)
		elif random.randf() < 0.25:
			picture.fill_rect(Rect2i(x, squash + random.randi_range(1, maxi(tall - 2, 1)), 1, 2), side[2])
	_ellipse(picture, middle, Vector2(radius, squash), rings[0])
	_ellipse(picture, middle, Vector2(radius - 1, squash - 1), rings[1])
	_ellipse(picture, middle, Vector2(maxf(radius * 0.4, 1.0), maxf(squash * 0.4, 1.0)), rings[2])
	return {"image": picture, "at": (foot - Vector2(radius, squash + tall)).round()}


## A rock: a dome lit from the top left, moss in the creases.
static func _rock(radius: int, tall: int, foot: Vector2, random: RandomNumberGenerator) -> Dictionary:
	var shade := mini(tall / 2, 16)
	var size := Vector2i(radius * 2 + shade + 1, tall + radius / 2 + 3)
	var picture := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var middle := Vector2(radius, tall)
	var half := Vector2(radius, tall)
	_ellipse(picture, Vector2(radius + shade * 0.6, tall + 1), Vector2(radius, maxf(radius / 2.0, 2.0)), Palette.GROUND_SHADOW, true)
	for y in tall + radius / 2:
		for x in radius * 2 + 1:
			var at := (Vector2(x, y) - middle) / half
			var squashed := Vector2(at.x, at.y if at.y < 0.0 else at.y * half.y / maxf(radius / 2.0, 1.0))
			if squashed.length() > 1.0:
				continue
			var light := -(squashed.x + squashed.y * 1.4)
			var color := Palette.SMOKE if light > 0.6 else (Palette.STEEL if light > -0.3 else Palette.STEEL_DARK)
			if color == Palette.STEEL and random.randf() < 0.05:
				color = Palette.MOSS
			picture.set_pixel(x, y, color)
	return {"image": picture, "at": (foot - Vector2(radius, tall)).round()}


## A bush: leaves heaped up, the shaded ones low, the lit ones on top.
static func _bush(radius: int, foot: Vector2, random: RandomNumberGenerator) -> Dictionary:
	var size := radius * 2 + 8
	var picture := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	_ellipse(picture, Vector2(size * 0.55, size * 0.8), Vector2(radius, maxf(radius / 3.0, 2.0)), Palette.GROUND_SHADOW, true)
	for index in 6:
		var lit := index >= 3
		var cluster := EnvironmentArt.leaves(random.randi_range(radius / 2, radius * 3 / 4), random.randi(), not lit)
		var at := Vector2(size * 0.5, size * (0.55 if lit else 0.65)) + Vector2(random.randf_range(-0.5, 0.5) * radius, random.randf_range(-0.25, 0.15) * radius) - Vector2(cluster.get_size()) / 2.0
		picture.blend_rect(cluster, Rect2i(Vector2i.ZERO, cluster.get_size()), Vector2i(at.round()))
	return {"image": picture, "at": (foot - Vector2(size * 0.5, size * 0.8)).round()}


## A shadow on the ground, dithered: every other pixel, so the ground shows through it.
static func _dither(picture: Image, area: Rect2i) -> void:
	for y in range(maxi(area.position.y, 0), mini(area.end.y, picture.get_height())):
		for x in range(maxi(area.position.x, 0), mini(area.end.x, picture.get_width())):
			if (x + y) % 2 == 0:
				picture.set_pixel(x, y, Palette.GROUND_SHADOW)


static func _ellipse(picture: Image, center: Vector2, half: Vector2, color: Color, dithered := false) -> void:
	for y in range(floori(center.y - half.y), ceili(center.y + half.y) + 1):
		for x in range(floori(center.x - half.x), ceili(center.x + half.x) + 1):
			if x < 0 or y < 0 or x >= picture.get_width() or y >= picture.get_height():
				continue
			var at := (Vector2(x, y) - center) / Vector2(maxf(half.x, 0.5), maxf(half.y, 0.5))
			if at.length_squared() <= 1.0 and (not dithered or (x + y) % 2 == 0):
				picture.set_pixel(x, y, color)
