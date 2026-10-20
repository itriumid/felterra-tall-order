class_name EnvironmentArt
extends RefCounted
## The forest, painted in code from the palette: the clearing's ground, grass and ferns, the trees
## at its edge and the leaves overhead. The environment has no outlines; characters do.

## A logged clearing a few months on: regrowth over most of it, mud where the machines drove.
static func ground(size: Vector2i, seed_value: int) -> Image:
	var growth := FastNoiseLite.new()
	growth.seed = seed_value
	growth.frequency = 0.006
	growth.fractal_octaves = 4
	var detail := FastNoiseLite.new()
	detail.seed = seed_value + 1
	detail.frequency = 0.08
	var growth_values := growth.get_image(size.x, size.y).get_data()
	var detail_values := detail.get_image(size.x, size.y).get_data()
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var data := PackedByteArray()
	data.resize(size.x * size.y * 4)
	for y in size.y:
		for x in size.x:
			var index := y * size.x + x
			var value := growth_values[index] / 255.0 + (detail_values[index] / 255.0 - 0.5) * 0.25
			# Dither one band into the next on a checkerboard, as pixel art does.
			value += 0.02 if (x + y) % 2 == 0 else -0.02
			var color: Color
			if value > 0.66:
				color = Palette.LEAF
			elif value > 0.5:
				color = Palette.JUNGLE
			elif value > 0.4:
				color = Palette.MOSS
			elif value > 0.33:
				color = Palette.MUD_LIGHT
			else:
				color = Palette.MUD
			var litter := random.randf()
			if litter < 0.01:
				color = Palette.DRY_GRASS
			elif litter < 0.016:
				color = Palette.LEAF_LIGHT
			elif litter < 0.02:
				color = Palette.JUNGLE_DARK
			data.encode_u32(index * 4, color.to_abgr32())
	var picture := Image.create_from_data(size.x, size.y, false, Image.FORMAT_RGBA8, data)
	_skid_trails(picture, random)
	return picture


## Where the logging machines dragged trunks out: bands of churned mud with tire tracks in them.
static func _skid_trails(picture: Image, random: RandomNumberGenerator) -> void:
	var size := picture.get_size()
	for trail in 3:
		var start := Vector2(random.randf_range(0.0, size.x), -20.0)
		var end := Vector2(random.randf_range(0.0, size.x), size.y + 20.0)
		if trail == 2:
			start = Vector2(-20.0, random.randf_range(0.2, 0.8) * size.y)
			end = Vector2(size.x + 20.0, random.randf_range(0.2, 0.8) * size.y)
		var bend := Vector2(random.randf_range(-300.0, 300.0), random.randf_range(-200.0, 200.0))
		var width := random.randf_range(34.0, 48.0)
		var steps := int(start.distance_to(end) / 3.0)
		var previous := start
		for step in steps + 1:
			var along := float(step) / steps
			var point := start.lerp(end, along) + bend * sin(along * PI)
			var across := (point - previous).normalized().orthogonal()
			previous = point
			var wobble := sin(along * 40.0) * 2.0
			_stamp(picture, point, width * 0.5 + wobble, Palette.MUD)
			_stamp(picture, point, width * 0.4 + wobble, Palette.MUD_LIGHT)
			# Two tire tracks, treads every few pixels.
			if step % 2 == 0:
				for side in [-1.0, 1.0]:
					var track: Vector2 = point + across * side * width * 0.22
					picture.fill_rect(Rect2i(Vector2i(track.round()) - Vector2i(2, 1), Vector2i(4, 2)), Palette.MUD_DARK)


static func _stamp(picture: Image, center: Vector2, radius: float, color: Color) -> void:
	var r := int(radius)
	for dy in range(-r, r + 1):
		var half := int(sqrt(maxf(radius * radius - dy * dy, 0.0)))
		picture.fill_rect(Rect2i(int(center.x) - half, int(center.y) + dy, half * 2 + 1, 1), color)


## A grass tuft, upright or bent over by something passing: its blades lean, the roots stay put.
static func tuft(lean: int) -> Image:
	var rows := ["...5...", ".5.4.5.", ".4.45.4", "4.444.4", ".34443.", "..333.."]
	return _greens(rows, lean, 3)


## A fern: low, wide fronds.
static func fern(lean: int) -> Image:
	var rows := [
		"......5......",
		"..5..454..5..",
		".454.444.454.",
		"4544443444454",
		".34433333443.",
		"..333222333..",
	]
	return _greens(rows, lean, 3)


static func _greens(rows: Array, lean: int, bending_rows: int) -> Image:
	var legend := {"2": Palette.JUNGLE_DARK, "3": Palette.JUNGLE, "4": Palette.LEAF, "5": Palette.LEAF_LIGHT}
	var width: int = rows[0].length() + 2
	var picture := Image.create_empty(width, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		# The tips lean furthest, the base not at all.
		var shift := 1 + (lean * (bending_rows - y) / bending_rows if y < bending_rows else 0)
		for x in rows[y].length():
			var key: String = rows[y][x]
			if legend.has(key):
				picture.set_pixel(clampi(x + shift, 0, width - 1), y, legend[key])
	return picture


## A tree at the jungle's edge: a trunk lit from the left, with bark streaks and buttress roots
## flaring at its foot.
static func trunk(height: int, width: int, seed_value: int) -> Image:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var flare := width * 2
	var picture := Image.create_empty(width + flare * 2, height, false, Image.FORMAT_RGBA8)
	for y in height:
		var near_foot := clampf(float(y - height + 18) / 18.0, 0.0, 1.0)
		var half := width * 0.5 + flare * near_foot * near_foot
		var center := picture.get_width() * 0.5
		for x in picture.get_width():
			var across := (x - center) / half
			if absf(across) > 1.0:
				continue
			var color := Palette.BARK
			if across < -0.45:
				color = Palette.BARK_LIGHT
			elif across > 0.5:
				color = Palette.MUD_DARK
			# Bark runs in vertical streaks.
			if (x * 5 + int(y / 6.0) * 3 + seed_value) % 9 == 0:
				color = Palette.MUD_DARK if color != Palette.MUD_DARK else Palette.BARK
			if near_foot > 0.0 and random.randf() < 0.05:
				color = Palette.MOSS
			picture.set_pixel(x, y, color)
	return picture


## A cluster of leaves, lit from the top left: many small leaves, not one blob.
static func leaves(radius: int, seed_value: int, dark: bool) -> Image:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var size := radius * 2 + 4
	var picture := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) * 0.5
	var shades := [Palette.JUNGLE_DEEP, Palette.JUNGLE_DARK, Palette.JUNGLE] if dark else [Palette.JUNGLE_DARK, Palette.JUNGLE, Palette.LEAF]
	for leaf in radius * 6:
		var at := center + Vector2.from_angle(random.randf() * TAU) * sqrt(random.randf()) * radius
		# Leaves toward the top left catch the light.
		var lit := (Vector2(-1, -1).normalized().dot((at - center) / radius) + 1.0) * 0.5
		var shade: Color = shades[clampi(int(lit * 3.0 + random.randf_range(-0.4, 0.4)), 0, 2)]
		var length := random.randi_range(2, 4)
		var direction := Vector2.from_angle(random.randf() * TAU)
		for step in length:
			var pixel := (at + direction * step).round()
			if Rect2(Vector2.ZERO, Vector2(size, size)).has_point(pixel):
				picture.set_pixelv(Vector2i(pixel), shade)
				picture.set_pixelv(Vector2i(pixel + Vector2(0, 1)).clamp(Vector2i.ZERO, Vector2i(size - 1, size - 1)), shade)
	return picture


## A banana plant's leaf, long and drooping, torn at the edges.
static func banana_leaf(length: int, seed_value: int) -> Image:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var picture := Image.create_empty(length + 2, length / 2 + 4, false, Image.FORMAT_RGBA8)
	for x in length:
		var along := float(x) / length
		var droop := int(along * along * length * 0.3)
		var half := int(sin(along * PI) * length * 0.13) + 1
		for dy in range(-half, half + 1):
			# Torn: the odd slit through to the rib.
			if dy != 0 and (x + seed_value) % 7 == 0 and random.randf() < 0.7:
				continue
			var color := Palette.LEAF if dy < 0 else Palette.JUNGLE
			if dy == 0:
				color = Palette.LEAF_LIGHT
			var y := 2 + half + droop + dy - int(length * 0.13)
			if y >= 0 and y < picture.get_height():
				picture.set_pixel(x, y, color)
	return picture
