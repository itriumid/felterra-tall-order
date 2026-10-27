class_name ForestMap
extends RefCounted
## The map of the forest the cats carved on the board at the gate, drawn the way a war map is: the
## forest cut into territories, each colored by who holds it and bordered off from its neighbors,
## the cats' pink, the company's hi-vis orange, and mist over what isn't found yet. A banner flies
## over each place held, and arrows go out from the cats' land into each place they can take
## next, the one chosen marching. Each place's own picture sits in it: wrecked while the company
## holds it, green again once it's free. The river runs down past the log slide. Endless lies off
## the map's top corner, beyond the territories.

## Where each place is on the map, as a share of its width and height.
const SPOTS := {
	"village": Vector2(0.07, 0.8), "edge": Vector2(0.19, 0.6), "deep": Vector2(0.3, 0.3),
	"sawpits": Vector2(0.44, 0.6), "clearing": Vector2(0.56, 0.27), "slide": Vector2(0.67, 0.66),
	"offices": Vector2(0.81, 0.45), "airstrip": Vector2(0.91, 0.2), "endless": Vector2(0.09, 0.2),
}
## The places the forest is cut into, in the order they're found from the village.
const TERRITORIES: Array[String] = ["village", "edge", "deep", "sawpits", "clearing", "slide", "offices", "airstrip"]
## The river, as a share of the map: it runs down past the log slide, under the path.
const RIVER: Array[Vector2] = [
	Vector2(0.77, 0.0), Vector2(0.74, 0.2), Vector2(0.75, 0.4), Vector2(0.72, 0.58),
	Vector2(0.62, 0.8), Vector2(0.6, 1.0),
]
## How big an area's picture is, in pixels.
const PATCH := Vector2(40, 28)
## Each holder's color on the map: the cats', the company's, and the mist's.
const COLORS := {"ours": Palette.PINK, "company": Palette.HI_VIS, "mist": Palette.SMOKE}
## How far a border wanders off straight, in pixels, so territories read as land, not cells.
const WANDER := 14.0

static var _cache := {}


## Draws the map in a box: rows are the board's places ({id, found, free}) in order, the area
## chosen is framed, and the one the next run goes to is pinned.
static func draw(canvas: CanvasItem, box: Rect2, rows: Array[Dictionary], choice: int, next_run: String) -> void:
	var holders := _holders(rows)
	canvas.draw_rect(box, Palette.JUNGLE_DARK)
	_canopy(canvas, box)
	_river(canvas, box)
	canvas.draw_texture(_territories(Vector2i(box.size), holders), box.position)
	# Arrows out of the cats' land into each place found and still the company's: from the place
	# before it, the way it was found.
	var marching := fmod(Time.get_ticks_msec() / 120.0, 6.0)
	for row in rows:
		var index := TERRITORIES.find(row.id)
		if index <= 0 or not row.found or row.free:
			continue
		var chosen: bool = rows[choice].id == row.id
		_arrow(canvas, _at(box, TERRITORIES[index - 1]), _at(box, row.id), Palette.PINK if chosen else Palette.BRASS_LIGHT, marching if chosen else 0.0)
	_village(canvas, _at(box, "village"))
	_banner(canvas, _at(box, "village") + Vector2(-13, -20), "ours")
	for index in rows.size():
		var row: Dictionary = rows[index]
		var patch := Rect2((_at(box, row.id) - PATCH / 2.0).floor(), PATCH)
		if row.id == "endless":
			_endless(canvas, patch)
		elif not row.found:
			_mist(canvas, patch)
		else:
			_area(canvas, patch, row.id, row.free)
			_banner(canvas, patch.position + Vector2(2, -12), holders.get(row.id, "mist"))
		if index == choice:
			canvas.draw_rect(patch.grow(2), Palette.PINK, false, 1.0)
			canvas.draw_rect(patch.grow(3), Palette.GRAPHITE, false, 1.0)
		if row.id == next_run:
			_pin(canvas, Vector2(patch.end.x - 4, patch.position.y - 2))
	_legend(canvas, box)
	canvas.draw_rect(box, Palette.BARK, false, 1.0)
	canvas.draw_rect(box.grow(1), Palette.OUTLINE, false, 1.0)


## The board's own map, carved and painted on the board at the gate: the same territories, each
## painted its holder's color, the river cut through them.
static func board_picture(size: Vector2i, liberated: Array) -> Image:
	var holders := {"village": "ours"}
	for index in range(1, TERRITORIES.size()):
		var id := TERRITORIES[index]
		holders[id] = "ours" if id in liberated else ("company" if TERRITORIES[index - 1] in liberated or index == 1 else "mist")
	var key := "board|%s|%s" % [size, holders]
	if _cache.has(key):
		return _cache[key]
	var owners := _owners(size, 1)
	var picture := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var paint := {"ours": Palette.LEAF, "company": Palette.HI_VIS, "mist": Palette.BARK_LIGHT}
	for y in size.y:
		for x in size.x:
			var owner: int = owners[y * size.x + x]
			var color: Color = paint[holders[TERRITORIES[owner]]]
			# The grooves between territories are carved: dark.
			if (x + 1 < size.x and owners[y * size.x + x + 1] != owner) or (y + 1 < size.y and owners[(y + 1) * size.x + x] != owner):
				color = Palette.BARK
			picture.set_pixel(x, y, color)
	for index in RIVER.size() - 1:
		var from := Vector2(size) * RIVER[index]
		var to := Vector2(size) * RIVER[index + 1]
		for step in int(from.distance_to(to)) + 1:
			var at := Vector2i(from.lerp(to, step / maxf(from.distance_to(to), 1.0)))
			if at.x >= 0 and at.y >= 0 and at.x < size.x and at.y < size.y:
				picture.set_pixelv(at, Palette.CLOTH)
	_cache[key] = picture
	return picture


## Who holds each territory: the cats, once it's free (and the village, always), the company where
## it's been found, and the mist where it hasn't.
static func _holders(rows: Array[Dictionary]) -> Dictionary:
	var holders := {"village": "ours"}
	for row in rows:
		if row.id in TERRITORIES:
			holders[row.id] = "ours" if row.free else ("company" if row.found else "mist")
	for id in TERRITORIES:
		if not holders.has(id):
			holders[id] = "ours"
	return holders


## Which territory each pixel of a map this size falls in, by index into TERRITORIES: the nearest
## place, its borders wandering a little. Worked out every so many pixels and filled in between.
static func _owners(size: Vector2i, every: int) -> PackedInt32Array:
	var key := "owners|%s|%d" % [size, every]
	if _cache.has(key):
		return _cache[key]
	var noise := FastNoiseLite.new()
	noise.seed = 39
	noise.frequency = 0.035
	var spots: Array[Vector2] = []
	for id in TERRITORIES:
		spots.append(Vector2(size) * (SPOTS[id] as Vector2))
	# A board's tiny map wanders less: its borders would be all wander.
	var wander := WANDER * minf(size.x / 400.0, 1.0)
	var owners := PackedInt32Array()
	owners.resize(size.x * size.y)
	for y in range(0, size.y, every):
		for x in range(0, size.x, every):
			var at := Vector2(x, y)
			# Warped a little before measuring, so the borders bend.
			var warped := at + Vector2(noise.get_noise_2d(x, y), noise.get_noise_2d(x + 300, y + 300)) * wander
			var best := 0
			var best_distance := INF
			for index in spots.size():
				var distance := warped.distance_squared_to(spots[index])
				if distance < best_distance:
					best_distance = distance
					best = index
			for fill_y in range(y, mini(y + every, size.y)):
				for fill_x in range(x, mini(x + every, size.x)):
					owners[fill_y * size.x + fill_x] = best
	_cache[key] = owners
	return owners


## The territories over the forest, as one picture: each marked in its holder's color, a band
## along its borders, so the canopy shows through inside. Between two holders, a dark border with
## the band either side; between two of the same holder, a faint one. Mist over what isn't found.
static func _territories(size: Vector2i, holders: Dictionary) -> ImageTexture:
	var key := "territories|%s|%s" % [size, holders]
	if _cache.has(key):
		return _cache[key]
	var owners := _owners(size, 2)
	var picture := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var holder_of := func(index: int) -> String: return holders[TERRITORIES[index]]
	for y in size.y:
		for x in size.x:
			var owner: int = owners[y * size.x + x]
			var holder: String = holder_of.call(owner)
			var color: Color = COLORS[holder]
			var other := -1
			for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var next := Vector2i(x, y) + offset
				if next.x >= 0 and next.y >= 0 and next.x < size.x and next.y < size.y and owners[next.y * size.x + next.x] != owner:
					other = owners[next.y * size.x + next.x]
			if other >= 0:
				if holder_of.call(other) != holder:
					picture.set_pixel(x, y, Palette.OUTLINE)
				elif (x + y) % 2 == 0:
					picture.set_pixel(x, y, color.darkened(0.3))
				continue
			# Just inside a border with someone else, a band of the holder's own color, solid, then
			# thinning out.
			var inside := 0
			for reach in range(1, 6):
				for offset: Vector2i in [Vector2i(reach, 0), Vector2i(-reach, 0), Vector2i(0, reach), Vector2i(0, -reach)]:
					var next := Vector2i(x, y) + offset
					if inside == 0 and next.x >= 0 and next.y >= 0 and next.x < size.x and next.y < size.y and holder_of.call(owners[next.y * size.x + next.x]) != holder:
						inside = reach
			if inside > 0 and inside <= 2:
				picture.set_pixel(x, y, color)
			elif inside > 0 and (x + y) % 2 == 0:
				picture.set_pixel(x, y, color)
			elif holder == "mist" and (x + y) % 2 == 0 and y % 2 == 0:
				# Mist over what isn't found; inside a held territory, the forest shows through.
				picture.set_pixel(x, y, color)
	var texture := ImageTexture.create_from_image(picture)
	_cache[key] = texture
	return texture


## An arrow from one place to another, stopping short of both pictures: a thick shaft and a head,
## outlined. A marching one has its shaft broken into dashes that move along it.
static func _arrow(canvas: CanvasItem, from: Vector2, to: Vector2, color: Color, marching: float) -> void:
	var along := (to - from).normalized()
	var start := from + along * 16.0
	var end := to - along * 20.0
	var length := start.distance_to(end)
	if length < 6.0:
		return
	var across := along.orthogonal()
	for step in int(length):
		var at := (start + along * step).floor()
		var dash := marching <= 0.0 or fmod(step + marching * 2.0, 12.0) < 8.0
		canvas.draw_rect(Rect2(at - Vector2(2, 2), Vector2(5, 5)), Palette.OUTLINE)
		if dash:
			canvas.draw_rect(Rect2(at - Vector2(1, 1), Vector2(3, 3)), color)
	var tip := end + along * 7.0
	var head := PackedVector2Array([tip, end + across * 6.0, end - across * 6.0])
	var rim := PackedVector2Array([tip + along * 2.0, end + across * 8.0 - along, end - across * 8.0 - along])
	canvas.draw_colored_polygon(rim, Palette.OUTLINE)
	canvas.draw_colored_polygon(head, color)


## A banner on a pole, in its holder's color: the cats' pink, the company's hi-vis orange.
static func _banner(canvas: CanvasItem, at: Vector2, holder: String) -> void:
	if holder == "mist":
		return
	at = at.floor()
	canvas.draw_rect(Rect2(at - Vector2(1, 1), Vector2(3, 14)), Palette.OUTLINE)
	canvas.draw_rect(Rect2(at, Vector2(1, 12)), Palette.BARK_LIGHT)
	canvas.draw_rect(Rect2(at + Vector2(1, -1), Vector2(10, 8)), Palette.OUTLINE)
	canvas.draw_rect(Rect2(at + Vector2(2, 0), Vector2(8, 6)), COLORS[holder])
	# A swallowtail, and the holder's mark: the cats' paw, the company's stripe.
	canvas.draw_rect(Rect2(at + Vector2(9, 2), Vector2(1, 2)), Palette.OUTLINE)
	if holder == "ours":
		canvas.draw_rect(Rect2(at + Vector2(4, 2), Vector2(3, 2)), Palette.CREAM)
		canvas.draw_rect(Rect2(at + Vector2(4, 1), Vector2(1, 1)), Palette.CREAM)
		canvas.draw_rect(Rect2(at + Vector2(6, 1), Vector2(1, 1)), Palette.CREAM)
	else:
		canvas.draw_rect(Rect2(at + Vector2(2, 2), Vector2(7, 1)), Palette.STEEL_LIGHT)


## Who holds what, in the map's corner.
static func _legend(canvas: CanvasItem, box: Rect2) -> void:
	var entries: Array = [["ours", "Ours"], ["company", "The company's"], ["mist", "Not found"]]
	var width := 0.0
	for entry: Array in entries:
		width += PixelFont.width(entry[1]) + 12
	var corner := Vector2(box.end.x - width - 6, box.end.y - PixelFont.LINE_HEIGHT - 6).floor()
	canvas.draw_rect(Rect2(corner - Vector2(3, 2), Vector2(width + 4, PixelFont.LINE_HEIGHT + 3)), Palette.PANEL_DARK)
	var x := corner.x
	for entry: Array in entries:
		canvas.draw_rect(Rect2(Vector2(x, corner.y + 2), Vector2(5, 5)), COLORS[entry[0]])
		PixelFont.draw(canvas, Vector2(x + 8, corner.y), entry[1], Palette.CREAM)
		x += PixelFont.width(entry[1]) + 12


static func _at(box: Rect2, id: String) -> Vector2:
	return (box.position + box.size * (SPOTS[id] as Vector2)).floor()


## The canopy from above: crowns of trees, dark below and lit from the top left, the same every
## time.
static func _canopy(canvas: CanvasItem, box: Rect2) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 39
	for crown in int(box.size.x * box.size.y / 90.0):
		var at := box.position + Vector2(random.randi_range(1, int(box.size.x) - 6), random.randi_range(1, int(box.size.y) - 6))
		var size := random.randi_range(3, 5)
		canvas.draw_rect(Rect2(at + Vector2(1, 1), Vector2(size, size)), Palette.JUNGLE_DEEP)
		canvas.draw_rect(Rect2(at, Vector2(size, size)), Palette.JUNGLE)
		canvas.draw_rect(Rect2(at, Vector2(1, 1)), Palette.LEAF)


static func _river(canvas: CanvasItem, box: Rect2) -> void:
	for index in RIVER.size() - 1:
		var from := box.position + box.size * RIVER[index]
		var to := box.position + box.size * RIVER[index + 1]
		var steps := int(from.distance_to(to))
		for step in steps:
			var at := from.lerp(to, float(step) / steps).floor()
			canvas.draw_rect(Rect2(at - Vector2(2, 0), Vector2(5, 1)), Palette.CLOTH)
			canvas.draw_rect(Rect2(at - Vector2(1, 0), Vector2(1, 1)), Palette.CLOTH_LIGHT)


static func _dotted(canvas: CanvasItem, from: Vector2, to: Vector2, color: Color) -> void:
	var steps := int(from.distance_to(to) / 4.0)
	for step in steps:
		var at := from.lerp(to, float(step) / steps).floor()
		canvas.draw_rect(Rect2(at, Vector2(2, 2)), color)


## The village: three huts and its banner, where every path starts.
static func _village(canvas: CanvasItem, at: Vector2) -> void:
	for hut: Vector2 in [Vector2(-9, -2), Vector2(-1, -5), Vector2(6, -1)]:
		var corner := at + hut
		canvas.draw_rect(Rect2(corner + Vector2(0, 3), Vector2(6, 4)), Palette.BARK_LIGHT)
		canvas.draw_rect(Rect2(corner + Vector2(-1, 1), Vector2(8, 2)), Palette.DRY_GRASS)
		canvas.draw_rect(Rect2(corner + Vector2(1, 0), Vector2(4, 1)), Palette.DRY_GRASS)
		canvas.draw_rect(Rect2(corner + Vector2(2, 5), Vector2(2, 2)), Palette.OUTLINE)


## An area found: wrecked while the company holds it, green again once it's free, with what makes
## it that place drawn on top.
static func _area(canvas: CanvasItem, patch: Rect2, id: String, free: bool) -> void:
	canvas.draw_rect(patch, Palette.LEAF if free else Palette.MUD)
	var random := RandomNumberGenerator.new()
	random.seed = absi(hash(id))
	# The ground: saplings and flowers, or ash and stumps.
	for mark in 14:
		var at := patch.position + Vector2(random.randi_range(1, int(patch.size.x) - 3), random.randi_range(1, int(patch.size.y) - 3))
		if free:
			canvas.draw_rect(Rect2(at, Vector2(2, 2)), Palette.LEAF_LIGHT if mark % 3 != 0 else Palette.JUNGLE)
			if mark % 5 == 0:
				canvas.draw_rect(Rect2(at + Vector2(0, -1), Vector2(1, 1)), Palette.PINK)
		else:
			canvas.draw_rect(Rect2(at, Vector2(3, 2)), Palette.BURNT if mark % 2 == 0 else Palette.MUD_DARK)
			if mark % 4 == 0:
				canvas.draw_rect(Rect2(at + Vector2(0, -1), Vector2(2, 2)), Palette.BARK_LIGHT)
	var middle := (patch.get_center() - Vector2(0, 1)).floor()
	match id:
		"edge":
			# The village's last hut, and the nest beside it.
			canvas.draw_rect(Rect2(middle + Vector2(-9, -1), Vector2(7, 5)), Palette.BARK_LIGHT)
			canvas.draw_rect(Rect2(middle + Vector2(-10, -3), Vector2(9, 2)), Palette.DRY_GRASS)
			if not free:
				canvas.draw_rect(Rect2(middle + Vector2(3, 0), Vector2(7, 4)), Palette.MUD_DARK)
				canvas.draw_rect(Rect2(middle + Vector2(4, -1), Vector2(5, 1)), Palette.RAT)
		"deep":
			# Tall trees, felled ones lying among them while it's held.
			for tree in [-10, -3, 5]:
				canvas.draw_rect(Rect2(middle + Vector2(tree, -8), Vector2(6, 7)), Palette.JUNGLE if free else Palette.JUNGLE_DARK)
				canvas.draw_rect(Rect2(middle + Vector2(tree + 2, -1), Vector2(2, 6)), Palette.BARK)
			if not free:
				canvas.draw_rect(Rect2(middle + Vector2(-8, 7), Vector2(14, 2)), Palette.BARK_LIGHT)
		"sawpits":
			# Two pits, and the saw's blade.
			for pit in [-11, 4]:
				canvas.draw_rect(Rect2(middle + Vector2(pit, 1), Vector2(7, 4)), Palette.MUD_DARK)
			if not free:
				canvas.draw_rect(Rect2(middle + Vector2(-3, -7), Vector2(6, 6)), Palette.STEEL)
				canvas.draw_rect(Rect2(middle + Vector2(-1, -5), Vector2(2, 2)), Palette.STEEL_DARK)
				canvas.draw_rect(Rect2(middle + Vector2(-4, -8), Vector2(1, 1)), Palette.STEEL_LIGHT)
		"clearing":
			# Stumps in rows where the fig grove was; saplings between them once it's free.
			for row in 2:
				for column in 4:
					var stump := middle + Vector2(-12 + column * 7, -5 + row * 7)
					canvas.draw_rect(Rect2(stump, Vector2(3, 2)), Palette.BARK_LIGHT)
					if free:
						canvas.draw_rect(Rect2(stump + Vector2(1, -2), Vector2(1, 2)), Palette.LEAF_LIGHT)
		"slide":
			# The chute of mud down to the river, logs on it while it's held.
			for step in 16:
				canvas.draw_rect(Rect2(middle + Vector2(-14 + step * 2, -8 + step), Vector2(3, 2)), Palette.MUD_DARK if not free else Palette.MOSS)
			if not free:
				canvas.draw_rect(Rect2(middle + Vector2(-6, -5), Vector2(5, 2)), Palette.BARK_LIGHT)
				canvas.draw_rect(Rect2(middle + Vector2(4, 1), Vector2(5, 2)), Palette.BARK_LIGHT)
		"offices":
			# Cabins in a row, with the hum of their lights while it's held.
			for cabin in [-12, -2, 8]:
				canvas.draw_rect(Rect2(middle + Vector2(cabin, -3), Vector2(7, 6)), Palette.STEEL if not free else Palette.BARK_LIGHT)
				canvas.draw_rect(Rect2(middle + Vector2(cabin - 1, -4), Vector2(9, 1)), Palette.STEEL_DARK if not free else Palette.MOSS)
				canvas.draw_rect(Rect2(middle + Vector2(cabin + 2, -1), Vector2(2, 2)), Palette.SPARK if not free else Palette.OUTLINE)
		"airstrip":
			# The strip, and the ribbon strung across it.
			canvas.draw_rect(Rect2(middle + Vector2(-16, -2), Vector2(32, 5)), Palette.STEEL_DARK if not free else Palette.DRY_GRASS)
			for dash in 5:
				canvas.draw_rect(Rect2(middle + Vector2(-13 + dash * 6, 0), Vector2(3, 1)), Palette.OFF_WHITE if not free else Palette.LEAF_LIGHT)
			if not free:
				canvas.draw_rect(Rect2(middle + Vector2(-1, -5), Vector2(1, 11)), Palette.SCARF_RED)
	if not free:
		# Smoke from what's burning, and the company's orange where it's working.
		canvas.draw_rect(Rect2(patch.position + Vector2(patch.size.x - 8, 2), Vector2(2, 2)), Palette.SMOKE)
		canvas.draw_rect(Rect2(patch.position + Vector2(patch.size.x - 6, 0), Vector2(2, 1)), Palette.SMOKE)
		canvas.draw_rect(Rect2(patch.position + Vector2(3, patch.size.y - 5), Vector2(2, 3)), Palette.HI_VIS)
	canvas.draw_rect(patch, Palette.OUTLINE, false, 1.0)


## Somewhere not found yet: mist over the trees, and a question.
static func _mist(canvas: CanvasItem, patch: Rect2) -> void:
	for y in int(patch.size.y):
		for x in int(patch.size.x):
			if (x + y) % 2 == 0:
				canvas.draw_rect(Rect2(patch.position + Vector2(x, y), Vector2(1, 1)), Palette.SMOKE)
	PixelFont.draw(canvas, (patch.get_center() - Vector2(PixelFont.width("?") / 2.0, PixelFont.ASCENT / 2.0 + 1)).floor(), "?", Palette.GRAPHITE)


## Endless: off the map, a fresh clearing every time, past where the paths go.
static func _endless(canvas: CanvasItem, patch: Rect2) -> void:
	canvas.draw_rect(patch, Palette.DRY_GRASS)
	for ring in 3:
		canvas.draw_rect(patch.grow(-4 - ring * 4), Palette.MOSS if ring % 2 == 0 else Palette.DRY_GRASS, false, 1.0)
	canvas.draw_rect(Rect2(patch.get_center() - Vector2(1, 1), Vector2(2, 2)), Palette.HI_VIS)
	canvas.draw_rect(patch, Palette.OUTLINE, false, 1.0)


## The pin on where the next run goes.
static func _pin(canvas: CanvasItem, at: Vector2) -> void:
	canvas.draw_rect(Rect2(at + Vector2(1, 3), Vector2(1, 4)), Palette.OUTLINE)
	canvas.draw_rect(Rect2(at - Vector2(1, 1), Vector2(5, 5)), Palette.OUTLINE)
	canvas.draw_rect(Rect2(at, Vector2(3, 3)), Palette.BRASS_LIGHT)
