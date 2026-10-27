class_name VillageView
extends EntitiesView
## The village and the forest path into it: the ground, the trees along the path, the houses on
## their stilts, the cats walking about, and the leaves overhead. Cats are drawn the way they are
## in the clearing; the rest is environment, painted in code with no outlines.

## How high a house's floor stands on its stilts, its walls, and its roof's peak over them, in
## meters.
const FLOOR := 0.35
const WALL := 0.9
const ROOF := 0.55
## Where the umbul-umbul stand: two at the village's way in, two either side of the longhouse.
const FLAG_POLES: Array[Vector2] = [Vector2(12.8, 7.3), Vector2(12.8, 10.8), Vector2(16.4, 3.9), Vector2(22.2, 3.9)]
## The umbul-umbul's colorways, bought from the weaver: festival, the brand's rhodonite, lagoon.
const BANNERS := {
	"festival": [Palette.SCARF_RED, Palette.BRASS_LIGHT, Palette.CREAM, Palette.PAINT_TEAL],
	"rhodonite": [Palette.PINK, Palette.GRAPHITE, Palette.PINK, Palette.CREAM],
	"lagoon": [Palette.PAINT_TEAL, Palette.CREAM, Palette.CLOTH_LIGHT, Palette.CREAM],
}
## Jogiboy's trot: the dogs' frames with all four feet down (reaching, then gathered under him),
## and how far he goes in one whole stride, in meters.
const JOGI_TROT: Array[int] = [0, 1, 0, 1]
const JOGI_STRIDE := 1.0
## Thatch, fresh and gold on a restored roof, with its shade and its catch of the light; and the
## same gone gray-brown on a ruin.
const THATCH := [Palette.BRASS, Palette.MUD_LIGHT, Palette.BRASS_LIGHT]
const OLD_THATCH := [Palette.BARK, Palette.MUD_DARK, Palette.BARK_LIGHT]
## Paint for restored walls and bunting: each hut its own.
const PAINTS: Array[Color] = [Palette.SCARF_RED, Palette.PAINT_TEAL, Palette.BRASS_LIGHT, Palette.PINK, Palette.CLOTH_LIGHT, Palette.LEAF_LIGHT]

var village: VillageMap
## What the village keeps, for the board's marks.
var village_record: Village
## The umbul-umbul's colors, as the village wears them, and a building being restored right now,
## with how long its dust has left to settle.
var banners := "festival"
var _restoring := ""
var _restoring_for := 0.0
var _ground: ImageTexture
var _trees: Array[Dictionary] = []
var _leaves: Array[Dictionary] = []


func _ready() -> void:
	var size := VillageMap.SIZE * World.PIXELS_PER_METER
	var worn: Array[Rect2] = []
	for patch in VillageMap.worn_ground():
		worn.append(Rect2(patch.position * World.PIXELS_PER_METER, patch.size * World.PIXELS_PER_METER))
	_ground = ImageTexture.create_from_image(EnvironmentArt.village_ground(
		Vector2i(size), 17, int(VillageMap.VILLAGE_FROM * World.PIXELS_PER_METER),
		int(VillageMap.PATH_TOP * World.PIXELS_PER_METER), int(VillageMap.PATH_BOTTOM * World.PIXELS_PER_METER), worn))
	var random := RandomNumberGenerator.new()
	random.seed = 23
	# The forest the path runs through: trees thick on either side of it, all the way up and down.
	var x := 0.3
	# The forest stops where the village starts: its last trees stand back from the village's
	# edge, so their crowns don't hang out over its open ground.
	while x < VillageMap.VILLAGE_FROM - 0.8:
		# Below the path the trunks stand back from it, so their crowns stop short of it.
		for band: Array in [[0.4, VillageMap.PATH_TOP - 0.5], [VillageMap.PATH_BOTTOM + 3.6, VillageMap.SIZE.y + 0.4]]:
			var y: float = band[0] + random.randf_range(0.0, 0.8)
			while y < band[1]:
				_plant_tree(Vector2(x + random.randf_range(-0.3, 0.3), y), random)
				y += random.randf_range(1.4, 2.2)
		x += random.randf_range(0.9, 1.5)
	# Around the village, the forest it was cut back from: behind it, past the gate but for the
	# path out, and along its foot a low hedge of undergrowth, which hides nothing.
	x = VillageMap.VILLAGE_FROM
	while x < VillageMap.SIZE.x:
		_plant_tree(Vector2(x, random.randf_range(0.05, 0.3)), random)
		x += random.randf_range(1.4, 2.4)
	x = VillageMap.VILLAGE_FROM - 0.5
	while x < VillageMap.SIZE.x + 0.5:
		var bush := EnvironmentArt.leaves(random.randi_range(10, 16), random.randi(), random.randf() < 0.5)
		var spot := Vector2(x, VillageMap.SIZE.y + random.randf_range(-0.1, 0.3))
		_leaves.append({"texture": ImageTexture.create_from_image(bush), "at": (World.to_screen(spot) - Vector2(bush.get_size()) / 2.0).round()})
		x += random.randf_range(0.4, 0.8)
	var y := 1.0
	while y < VillageMap.SIZE.y:
		if y < VillageMap.PATH_TOP - 0.6 or y > VillageMap.PATH_BOTTOM + 0.8:
			_plant_tree(Vector2(VillageMap.SIZE.x - random.randf_range(0.0, 0.3), y), random)
		y += random.randf_range(1.2, 2.0)
	# Leaves overhead: heavy over the forest path, open over the village.
	for index in 140:
		var spot := Vector2(random.randf_range(0.0, VillageMap.VILLAGE_FROM - 0.6), random.randf_range(-0.2, VillageMap.SIZE.y + 0.2))
		if spot.y > VillageMap.PATH_TOP + 0.4 and spot.y < VillageMap.PATH_BOTTOM - 0.4 and random.randf() < 0.7:
			continue
		var picture := EnvironmentArt.leaves(random.randi_range(12, 22), random.randi(), random.randf() < 0.6)
		_leaves.append({"texture": ImageTexture.create_from_image(picture), "at": (World.to_screen(spot) - Vector2(picture.get_size()) / 2.0).round()})


func _plant_tree(foot: Vector2, random: RandomNumberGenerator) -> void:
	var height := random.randi_range(80, 130)
	var picture := EnvironmentArt.trunk(height, random.randi_range(8, 14), random.randi())
	_trees.append({"texture": ImageTexture.create_from_image(picture), "at": (World.to_screen(foot) - Vector2(picture.get_width() / 2, height)).round(), "y": foot.y})
	# Its crown on top, with the leaves overhead.
	var crown := EnvironmentArt.crown(random.randi_range(24, 32), random.randi())
	_leaves.append({"texture": ImageTexture.create_from_image(crown), "at": (World.to_screen(foot) - Vector2(0, height + 4) - Vector2(crown.get_size()) / 2.0).round()})


func _process(delta: float) -> void:
	if village == null:
		return
	var walkers: Array = [village.cat, village.elder, village.jogi] + village.villagers
	var walked := {}
	var last := {}
	for walker: Cat in walkers:
		var moved: float = walker.body.position.distance_to(_last.get(walker, walker.body.position))
		walked[walker] = _walked.get(walker, 0.0) + moved
		last[walker] = walker.body.position
	_walked = walked
	_last = last
	_clock += delta
	_restoring_for = maxf(_restoring_for - delta, 0.0)
	_settle_dust(delta)
	queue_redraw()


## A building just restored: a burst of dust and wood chips over it as it comes back.
func restoring(building_name: String) -> void:
	for building in village.buildings:
		if building.name != building_name:
			continue
		var footprint: Rect2 = building.footprint
		for index in 40:
			_dust.append({
				"position": Vector2(randf_range(footprint.position.x, footprint.end.x), footprint.end.y + randf_range(-0.2, 0.3)),
				"height": randf_range(0.0, 1.0), "velocity": Vector2(randf_range(-0.8, 0.8), randf_range(-0.3, 0.3)),
				"rise": randf_range(0.4, 1.4), "life": randf_range(0.5, 1.2),
			})


func _draw() -> void:
	if village == null:
		return
	draw_texture(_ground, Vector2.ZERO)
	var standing: Array[Array] = []
	for tree in _trees:
		standing.append([tree.y, tree])
	for building in village.buildings:
		standing.append([(building.footprint as Rect2).end.y, building])
	for prop: Dictionary in VillageMap.PROPS:
		if prop.kind != "mat":
			standing.append([(prop.footprint as Rect2).end.y, {"prop": prop}])
	standing.append([village.cat.body.position.y, village.cat])
	standing.append([village.elder.body.position.y, village.elder])
	standing.append([village.jogi.body.position.y, {"jogi": village.jogi}])
	for villager in village.villagers:
		standing.append([villager.body.position.y, villager])
	var longhouse_restored: bool = village.buildings.any(func(building: Dictionary) -> bool: return building.name == "longhouse" and building.restored)
	for pole: Vector2 in FLAG_POLES:
		standing.append([pole.y, {"pole": pole, "restored": longhouse_restored}])
	standing.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for building in village.buildings:
		if building.restored:
			_draw_flowers(building.footprint)
	for prop: Dictionary in VillageMap.PROPS:
		if prop.kind == "mat":
			_draw_mat(prop.footprint)
	for entry in standing:
		if entry[1] is Cat:
			_draw_shadow(entry[1])
	for entry in standing:
		var thing: Variant = entry[1]
		if thing is Cat:
			_draw_cat(thing)
		elif thing.has("texture"):
			draw_texture(thing.texture, thing.at)
		elif thing.has("pole"):
			_draw_flag(thing.pole, thing.restored)
		elif thing.has("jogi"):
			_draw_jogi(thing.jogi)
		elif thing.has("prop"):
			_draw_prop(thing.prop)
		else:
			_draw_building(thing)
	for speck in _dust:
		draw_rect(Rect2(World.to_screen(speck.position, speck.height), Vector2.ONE), Palette.SMOKE)
	for cluster in _leaves:
		draw_texture(cluster.texture, cluster.at)


func _draw_building(building: Dictionary) -> void:
	var footprint: Rect2 = building.footprint
	var restored: bool = building.restored
	match building.kind:
		"board": _draw_board(footprint)
		"smithy": _draw_smithy(footprint, restored)
		"longhouse": _draw_house(footprint, restored, -1)
		"watchtower": _draw_watchtower(footprint, restored)
		"market": _draw_market(footprint, restored, _lifted(footprint))
		"healer":
			_draw_house(footprint, restored, building.paint)
			_draw_herbs(footprint, restored)
		_: _draw_house(footprint, restored, building.paint)


## Whether a building below the road has its roof lifted off: he's behind it, at its door on the
## road side, where it would hide him.
func _lifted(footprint: Rect2) -> bool:
	var at := village.cat.body.position
	return VillageMap.faces_up(footprint) and at.x > footprint.position.x - 0.3 and at.x < footprint.end.x + 0.3 \
		and at.y < footprint.position.y and at.y > footprint.position.y - 1.6


## A house on stilts, drawn the cartoon way: chunky posts, walls a touch out of true, an arched
## door and round windows with their shutters, and a big puffy thatch whose scalloped edge hangs
## over the walls. Below the road, its door is on the far side, facing the road: what shows is its
## back wall, with two windows; and with him at that door, the roof lifts off (see
## _draw_open_house).
##
## Restored, it's painted (each hut its own color, trimmed in cream), with flower boxes under the
## windows and bunting under the eaves; the longhouse carries a painted band along its walls and
## carved, painted gable boards. A ruin is the same house after the machines: the walls holed,
## scorched and broken off along the top, half the roof gone to bare rafters, planks on the
## ground, a scrap of bunting left hanging.
func _draw_house(footprint: Rect2, restored: bool, paint: int) -> void:
	if _lifted(footprint):
		_draw_open_house(footprint, restored, paint)
		return
	var turned := VillageMap.faces_up(footprint)
	var longhouse := paint < 0
	var front := footprint.end.y
	var back := footprint.position.y
	var left := footprint.position.x
	var right := footprint.end.x
	var eaves := FLOOR + WALL
	var peak := eaves + ROOF * (1.6 if longhouse else 1.5)
	var ridge := (front + back) / 2.0
	var overhang := 0.4
	# The thatch's edge, out over the wall and a little down it.
	var lip := front + 0.15
	var lip_height := eaves - 0.05
	var color: Color = Palette.CREAM if longhouse else PAINTS[paint % PAINTS.size()]
	# The stilts, chunky, lit down their left sides, and the shadow under the floor.
	_quad([Vector2(left, front), Vector2(right, front)], 0.0, FLOOR, Palette.JUNGLE_DARK)
	var post := left + 0.1
	while post <= right - 0.1:
		var height := FLOOR if restored or fmod(post, 1.3) > 0.4 else FLOOR * 0.5
		_quad([Vector2(post, front), Vector2(post + 0.12, front)], 0.0, height, Palette.BARK)
		_quad([Vector2(post, front), Vector2(post + 0.03, front)], 0.0, height, Palette.BARK_LIGHT)
		post += 0.7
	_quad([Vector2(left - 0.05, front + 0.05), Vector2(right + 0.05, front + 0.05)], FLOOR - 0.06, FLOOR + 0.03, Palette.BARK_LIGHT)
	var middle := (left + right) / 2.0
	if restored:
		# The wall, its right end sagged a pixel or two, framed by corner posts.
		draw_colored_polygon(PackedVector2Array([
			World.to_screen(Vector2(left, front), FLOOR), World.to_screen(Vector2(right, front), FLOOR),
			World.to_screen(Vector2(right, front), eaves - 0.05), World.to_screen(Vector2(left, front), eaves),
		]), color)
		_quad([Vector2(left, front), Vector2(right, front)], FLOOR, FLOOR + 0.08, Palette.CREAM if not longhouse else Palette.SCARF_RED)
		for corner in [left, right - 0.08]:
			_quad([Vector2(corner, front), Vector2(corner + 0.08, front)], FLOOR, eaves, Palette.BARK_LIGHT)
		if longhouse:
			_band(left, right, front, FLOOR + 0.2)
		# The door under its arch, its brass knob catching the light; turned from us, a second
		# window where the door would be.
		if not turned:
			_arch(middle, front, 0.24, 0.4, Palette.BARK_LIGHT if longhouse else Palette.CREAM)
			_arch(middle, front, 0.18, 0.38, Palette.BARK)
			draw_rect(Rect2(World.to_screen(Vector2(middle + 0.1, front), FLOOR + 0.25), Vector2.ONE), Palette.BRASS_LIGHT)
		for window_x in ([left + 0.5, right - 0.5] if longhouse or turned else [left + 0.45]):
			_round_window(window_x, front)
	else:
		_quad([Vector2(left, front), Vector2(right, front)], FLOOR, eaves, Palette.DRY_GRASS)
		var row := FLOOR + 0.1
		while row < eaves:
			draw_line(World.to_screen(Vector2(left, front), row), World.to_screen(Vector2(right, front), row), Palette.MOSS)
			row += 0.15
		# Scorched along one side, holed through, the door hanging open on the dark (or, turned from
		# us, the window frame torn out).
		_quad([Vector2(right - (right - left) * 0.35, front), Vector2(right, front)], FLOOR, eaves, Palette.BURNT)
		if turned:
			_quad([Vector2(middle - 0.2, front), Vector2(middle + 0.2, front)], FLOOR + 0.25, FLOOR + 0.55, Palette.JUNGLE_DEEP)
		else:
			_arch(middle, front, 0.2, 0.36, Palette.JUNGLE_DEEP)
		_quad([Vector2(left + 0.25, front), Vector2(left + 0.55, front)], FLOOR + 0.25, FLOOR + 0.5, Palette.JUNGLE_DEEP)
		# The wall broken off along its top: what's left stands at uneven heights.
		var column := left
		var step := 0
		while column < right:
			var lost: float = [0.0, 0.25, 0.12, 0.35, 0.05, 0.2][step % 6]
			_quad([Vector2(column, front), Vector2(minf(column + 0.18, right), front)], eaves - lost, eaves, Palette.JUNGLE_DARK)
			column += 0.18
			step += 1
	# The roof: whole and thatched once restored; on a ruin, the back slope gone, half the front
	# fallen in, and bare rafters where it was.
	if restored:
		_slope(Vector2(left - overhang, ridge), Vector2(right + overhang, ridge), peak, Vector2(left - overhang, back - 0.15), Vector2(right + overhang, back - 0.15), eaves, THATCH[1])
		_slope(Vector2(left - overhang, ridge), Vector2(right + overhang, ridge), peak, Vector2(left - overhang, lip), Vector2(right + overhang, lip), lip_height, THATCH[0])
		_thatch(left - overhang, right + overhang, ridge, peak, lip, lip_height)
		_bunting(left - overhang + 0.1, right + overhang - 0.1, lip, lip_height - 0.12)
		if longhouse:
			for end_x in [left - overhang, right + overhang]:
				var top := World.to_screen(Vector2(end_x, ridge), peak)
				draw_line(top, top + Vector2(-5, -7), Palette.SCARF_RED)
				draw_line(top, top + Vector2(5, -7), Palette.BRASS_LIGHT)
		else:
			# A pennant at the ridge's end, in the house's own color.
			var top := World.to_screen(Vector2(right + overhang - 0.15, ridge), peak) + Vector2(0, -2)
			draw_line(top, top + Vector2(0, -9), Palette.BARK)
			draw_colored_polygon(PackedVector2Array([top + Vector2(1, -9), top + Vector2(8, -7), top + Vector2(1, -5)]), color)
	else:
		var kept := left - overhang + (right - left + overhang * 2.0) * 0.45
		_slope(Vector2(left - overhang, ridge), Vector2(kept, ridge), peak, Vector2(left - overhang, lip), Vector2(kept - 0.3, lip), lip_height, OLD_THATCH[0])
		_thatch(left - overhang, kept - 0.3, ridge, peak, lip, lip_height, OLD_THATCH)
		var rafter := kept
		while rafter < right + overhang:
			draw_line(World.to_screen(Vector2(rafter, ridge), peak), World.to_screen(Vector2(rafter - 0.1, lip), lip_height), Palette.BARK)
			rafter += 0.4
		draw_line(World.to_screen(Vector2(kept, ridge), peak), World.to_screen(Vector2(right + overhang, ridge), peak - 0.15), Palette.BARK)
		# Planks fallen in front, and what's left of the bunting.
		for plank in 3:
			var from := Vector2(left + 0.2 + plank * (right - left) * 0.3, front + 0.25 + plank % 2 * 0.15)
			draw_line(World.to_screen(from), World.to_screen(from + Vector2(0.5, 0.08 - plank * 0.06)), Palette.BARK_LIGHT)
		var hook := World.to_screen(Vector2(left - overhang + 0.15, lip), lip_height) + Vector2(0, 3)
		draw_colored_polygon(PackedVector2Array([hook, hook + Vector2(3, 0), hook + Vector2(1, 4)]), Palette.PINK)
		draw_colored_polygon(PackedVector2Array([hook + Vector2(4, 1), hook + Vector2(7, 1), hook + Vector2(5, 4)]), Palette.BRASS)


## A doorway on a front wall: upright sides to a height, under a round arch, in one color.
func _arch(middle: float, front: float, half_width: float, height: float, color: Color) -> void:
	_quad([Vector2(middle - half_width, front), Vector2(middle + half_width, front)], FLOOR, FLOOR + height, color)
	draw_circle(World.to_screen(Vector2(middle, front), FLOOR + height), roundf(half_width * World.PIXELS_PER_METER), color)


## A round window on a front wall, from its left edge: its frame crossed in cream, the dark
## inside, its shutters thrown open either side, and a box of flowers under it.
func _round_window(left: float, front: float) -> void:
	var center := World.to_screen(Vector2(left + 0.17, front), FLOOR + 0.45)
	for side in [-1, 1]:
		draw_rect(Rect2(center + Vector2(side * 8 - (3 if side < 0 else 0), -5), Vector2(3, 10)), Palette.BARK_LIGHT)
		draw_rect(Rect2(center + Vector2(side * 8 - (3 if side < 0 else 0), -1), Vector2(3, 1)), Palette.BARK)
	draw_circle(center, 6, Palette.CREAM)
	draw_circle(center, 4, Palette.JUNGLE_DEEP)
	draw_rect(Rect2(center + Vector2(-4, 0), Vector2(9, 1)), Palette.CREAM)
	draw_rect(Rect2(center + Vector2(0, -4), Vector2(1, 9)), Palette.CREAM)
	var box := center + Vector2(-6, 7)
	draw_rect(Rect2(box, Vector2(13, 2)), Palette.BARK_LIGHT)
	for flower in 5:
		draw_rect(Rect2(box + Vector2(1 + flower * 2.5, -1).round(), Vector2(1, 1)), [Palette.PINK, Palette.BRASS_LIGHT, Palette.SCARF_RED, Palette.CREAM, Palette.PINK][flower])
		draw_rect(Rect2(box + Vector2(1 + flower * 2.5, 0).round(), Vector2(1, 1)), Palette.LEAF)


## A house below the road with him at its door: the roof lifted off and the walls cut down to the
## sill, so he shows behind it. The floor on its stilts, the walls knee high in their paint (or
## scorched grass, in a ruin), and the door a gap in the far wall, with steps down to the road.
func _draw_open_house(footprint: Rect2, restored: bool, paint: int) -> void:
	var front := footprint.end.y
	var back := footprint.position.y
	var left := footprint.position.x
	var right := footprint.end.x
	var middle := (left + right) / 2.0
	var sill := FLOOR + 0.25
	var wall: Color = PAINTS[paint % PAINTS.size()] if restored else Palette.DRY_GRASS
	_quad([Vector2(left, front), Vector2(right, front)], 0.0, FLOOR, Palette.JUNGLE_DARK)
	# The steps, from the doorway down to the road.
	for step in 3:
		var y := back - 0.08 - step * 0.08
		_slope(Vector2(middle - 0.25, y), Vector2(middle + 0.25, y), FLOOR - step * 0.12, Vector2(middle - 0.25, y + 0.08), Vector2(middle + 0.25, y + 0.08), FLOOR - step * 0.12, Palette.BARK_LIGHT)
		_quad([Vector2(middle - 0.25, y), Vector2(middle + 0.25, y)], FLOOR - (step + 1) * 0.12, FLOOR - step * 0.12, Palette.BARK)
	# The far wall, either side of the doorway, then the floor, plank by plank.
	_quad([Vector2(left, back), Vector2(middle - 0.22, back)], FLOOR, sill, wall)
	_quad([Vector2(middle + 0.22, back), Vector2(right, back)], FLOOR, sill, wall)
	_slope(Vector2(left, back), Vector2(right, back), FLOOR, Vector2(left, front), Vector2(right, front), FLOOR, Palette.BARK_LIGHT if restored else Palette.BARK)
	var plank := back + 0.2
	while plank < front:
		draw_line(World.to_screen(Vector2(left, plank), FLOOR), World.to_screen(Vector2(right, plank), FLOOR), Palette.BARK)
		plank += 0.2
	if not restored:
		_slope(Vector2(right - 0.8, back + 0.3), Vector2(right - 0.2, back + 0.3), FLOOR, Vector2(right - 0.9, front - 0.3), Vector2(right - 0.3, front - 0.3), FLOOR, Palette.BURNT)
	# The side walls along their tops, and the near wall.
	for side_x in [left, right - 0.06]:
		_slope(Vector2(side_x, back), Vector2(side_x + 0.06, back), sill, Vector2(side_x, front), Vector2(side_x + 0.06, front), sill, wall)
	_quad([Vector2(left, front), Vector2(right, front)], FLOOR, sill, wall)
	_quad([Vector2(left, front), Vector2(right, front)], sill - 0.04, sill, Palette.CREAM if restored else Palette.JUNGLE_DARK)


## A prop of the village's, by its kind: the well, a bench, a garden, the woodpile, the washing
## line or a coconut palm. The rice mat is drawn flat on the ground, under everything.
func _draw_prop(prop: Dictionary) -> void:
	var footprint: Rect2 = prop.footprint
	match prop.kind:
		"well": _draw_well(footprint)
		"bench": _draw_bench(footprint)
		"garden": _draw_garden(footprint)
		"woodpile": _draw_woodpile(footprint)
		"washing": _draw_washing(footprint)
		"palm": _draw_palm(footprint)


## The well in the square: a round wall of stones, the water dark inside, two posts and a little
## thatched roof over it, and the bucket hanging on its rope.
func _draw_well(footprint: Rect2) -> void:
	var center := footprint.get_center()
	var radius := Vector2(footprint.size.x / 2.0, footprint.size.y / 2.0)
	var rim := 0.45
	# The wall: its near half, stones in courses, then its top ring and the water.
	var near := PackedVector2Array()
	for step in 13:
		var angle := PI * step / 12.0
		near.append(World.to_screen(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y), 0.0))
	for step in 13:
		var angle := PI - PI * step / 12.0
		near.append(World.to_screen(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y), rim))
	draw_colored_polygon(near, Palette.STEEL)
	for course in 3:
		var height := 0.12 + course * 0.13
		var from := World.to_screen(center + Vector2(-radius.x, 0.0), height)
		var to := World.to_screen(center + Vector2(radius.x, 0.0), height)
		var x := from.x + (2 if course % 2 == 0 else 5)
		while x < to.x - 2:
			draw_rect(Rect2(Vector2(x, from.y + 2), Vector2(1, 3)), Palette.STEEL_DARK)
			x += 6
		draw_line(from + Vector2(1, 2), to + Vector2(-1, 2), Palette.STEEL_DARK)
	draw_line(World.to_screen(center + Vector2(-radius.x, 0.0), rim), World.to_screen(center + Vector2(-radius.x, 0.0), 0.0), Palette.STEEL_LIGHT)
	var top := World.to_screen(center, rim)
	var size := Vector2(radius.x, radius.y) * World.PIXELS_PER_METER
	_ellipse(top, size, Palette.STEEL_LIGHT)
	_ellipse(top, size - Vector2(4, 3), Palette.JUNGLE_DEEP)
	# The posts, the roof over it, and the bucket on its rope.
	for side in [-1, 1]:
		var foot := center + Vector2(side * (radius.x - 0.05), 0.0)
		_quad([foot, foot + Vector2(0.07, 0.0)], rim, 1.75, Palette.BARK)
	var ridge := center
	_slope(ridge + Vector2(-radius.x - 0.2, 0.0), ridge + Vector2(radius.x + 0.2, 0.0), 2.0, center + Vector2(-radius.x - 0.2, 0.3), center + Vector2(radius.x + 0.2, 0.3), 1.7, THATCH[0])
	_thatch(center.x - radius.x - 0.2, center.x + radius.x + 0.2, ridge.y, 2.0, center.y + 0.3, 1.7)
	var hang := World.to_screen(center, 1.65)
	draw_line(hang, hang + Vector2(0, 14), Palette.BARK_LIGHT)
	draw_rect(Rect2(hang + Vector2(-3, 14), Vector2(7, 5)), Palette.BARK_LIGHT)
	draw_rect(Rect2(hang + Vector2(-3, 14), Vector2(7, 1)), Palette.BRASS)


## A filled ellipse around a point on the screen, its half width and half height in pixels.
func _ellipse(center: Vector2, half: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for step in 20:
		var angle := TAU * step / 20.0
		points.append((center + Vector2(cos(angle) * half.x, sin(angle) * half.y)).round())
	draw_colored_polygon(points, color)


## A bench of planks on two legs, where the old cats sit and watch the square.
func _draw_bench(footprint: Rect2) -> void:
	var front := footprint.end.y
	for leg_x in [footprint.position.x + 0.1, footprint.end.x - 0.18]:
		_quad([Vector2(leg_x, front), Vector2(leg_x + 0.08, front)], 0.0, 0.3, Palette.BARK)
	_slope(Vector2(footprint.position.x, footprint.position.y), Vector2(footprint.end.x, footprint.position.y), 0.32, Vector2(footprint.position.x, front), Vector2(footprint.end.x, front), 0.32, Palette.BARK_LIGHT)
	_quad([Vector2(footprint.position.x, front), Vector2(footprint.end.x, front)], 0.26, 0.32, Palette.BARK)


## A kitchen garden behind a low bamboo fence: rows of greens in dark earth, chilies red among
## them and the odd marigold.
func _draw_garden(footprint: Rect2) -> void:
	var left := footprint.position.x
	var right := footprint.end.x
	var back := footprint.position.y
	var front := footprint.end.y
	_fence(left, right, back)
	_slope(Vector2(left, back), Vector2(right, back), 0.0, Vector2(left, front), Vector2(right, front), 0.0, Palette.MUD_DARK)
	var random := RandomNumberGenerator.new()
	random.seed = hash(footprint)
	var row := back + 0.25
	while row < front - 0.1:
		var x := left + 0.15
		while x < right - 0.1:
			var at := World.to_screen(Vector2(x, row))
			draw_rect(Rect2(at + Vector2(-1, -3), Vector2(3, 3)), Palette.LEAF)
			draw_rect(Rect2(at + Vector2(0, -4), Vector2(1, 1)), Palette.LEAF_LIGHT)
			var fruit := random.randf()
			if fruit < 0.3:
				draw_rect(Rect2(at + Vector2(1, -2), Vector2.ONE), Palette.SCARF_RED)
			elif fruit < 0.4:
				draw_rect(Rect2(at + Vector2(0, -5), Vector2(2, 2)), Palette.BRASS_LIGHT)
			x += 0.22
		row += 0.32
	for side in [left, right]:
		var points := 0.0
		while points < front - back:
			_quad([Vector2(side, back + points), Vector2(side, back + points + 0.05)], 0.0, 0.4, Palette.DRY_GRASS)
			points += 0.3
	_fence(left, right, front)


## A run of low bamboo fence, posts and two rails, light along their tops.
func _fence(left: float, right: float, y: float) -> void:
	var post := left
	while post <= right:
		_quad([Vector2(post, y), Vector2(post + 0.05, y)], 0.0, 0.42, Palette.DRY_GRASS)
		post += 0.3
	for rail in [0.15, 0.32]:
		_quad([Vector2(left, y), Vector2(right, y)], rail, rail + 0.04, Palette.DRY_GRASS)
		draw_line(World.to_screen(Vector2(left, y), rail + 0.04), World.to_screen(Vector2(right, y), rail + 0.04), Palette.BRASS_LIGHT)


## Firewood for the forge, stacked log on log, their cut ends to us.
func _draw_woodpile(footprint: Rect2) -> void:
	var front := footprint.end.y
	var count := int(footprint.size.x / 0.2)
	for layer in 3:
		for log in count - layer:
			var at := World.to_screen(Vector2(footprint.position.x + 0.1 + log * 0.2 + layer * 0.1, front), 0.08 + layer * 0.16)
			draw_circle(at, 4, Palette.BARK)
			draw_circle(at, 3, Palette.BARK_LIGHT)
			draw_rect(Rect2(at, Vector2.ONE), Palette.MUD)


## A washing line strung between two posts, the village's sarongs and shirts drying on it and
## stirring in the air.
func _draw_washing(footprint: Rect2) -> void:
	var y := footprint.position.y
	var left := footprint.position.x
	var right := footprint.end.x
	for post_x in [left, right - 0.07]:
		_quad([Vector2(post_x, y), Vector2(post_x + 0.07, y)], 0.0, 1.3, Palette.BARK)
	var from := World.to_screen(Vector2(left + 0.03, y), 1.25)
	var to := World.to_screen(Vector2(right - 0.03, y), 1.25)
	var colors: Array[Color] = [Palette.SCARF_RED, Palette.CREAM, Palette.PAINT_TEAL, Palette.BRASS_LIGHT, Palette.CLOTH_LIGHT, Palette.PINK]
	var sag := 4.0
	for x in range(int(from.x), int(to.x)):
		var share := (x - from.x) / (to.x - from.x)
		draw_rect(Rect2(Vector2(x, from.y + roundf(sin(share * PI) * sag)), Vector2.ONE), Palette.BARK_LIGHT)
	for cloth in colors.size():
		var share := (cloth + 0.6) / (colors.size() + 0.2)
		var x := roundf(lerpf(from.x, to.x, share))
		var top := from.y + roundf(sin(share * PI) * sag) + 1
		var sway := 1.0 if (int(_clock * 1.5) + cloth) % 3 == 0 else 0.0
		var size := Vector2(8, 10 + cloth % 3 * 3)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 4, top), Vector2(x + 4, top), Vector2(x + 4 + sway, top + size.y), Vector2(x - 4 + sway, top + size.y)]), colors[cloth])
		draw_rect(Rect2(Vector2(x - 4, top), Vector2(8, 1)), Palette.BARK_LIGHT)


## Rice drying in the sun on a woven mat, raked into furrows.
func _draw_mat(footprint: Rect2) -> void:
	_slope(footprint.position, Vector2(footprint.end.x, footprint.position.y), 0.0, Vector2(footprint.position.x, footprint.end.y), footprint.end, 0.0, Palette.DRY_GRASS)
	var from := World.to_screen(footprint.position)
	var to := World.to_screen(footprint.end)
	for y in range(int(from.y) + 2, int(to.y) - 1, 3):
		for x in range(int(from.x) + 2, int(to.x) - 2):
			if (x + y) % 4 != 0:
				draw_rect(Rect2(Vector2(x, y), Vector2.ONE), Palette.BRASS_LIGHT)
	draw_rect(Rect2(from, to - from), Palette.BARK_LIGHT, false)


## A coconut palm: its trunk leaning and ringed, a crown of fronds drooping all round, and
## coconuts under them, stirring a little in the air.
func _draw_palm(footprint: Rect2) -> void:
	var foot := World.to_screen(footprint.get_center())
	var height := 120
	var lean := 14.0 if int(footprint.position.x) % 2 == 0 else -12.0
	var top := foot + Vector2(lean, -height)
	draw_rect(Rect2(foot + Vector2(-9, -2), Vector2(18, 4)), Palette.GROUND_SHADOW)
	for step in height:
		var share := float(step) / height
		var at := (foot + Vector2(lean * share * share, -step)).round()
		draw_rect(Rect2(at + Vector2(-2, 0), Vector2(5, 1)), Palette.BARK_LIGHT if step % 7 != 0 else Palette.BARK)
		draw_rect(Rect2(at + Vector2(-2, 0), Vector2(1, 1)), Palette.DRY_GRASS)
	var sway := sin(_clock * 1.2 + footprint.position.x) * 1.5
	for frond in 8:
		var angle := TAU * frond / 8.0 + 0.2
		var reach := Vector2(cos(angle) * 26.0, sin(angle) * 9.0)
		var previous := top
		for part in 12:
			var share := (part + 1) / 12.0
			var at := (top + reach * share + Vector2(sway * share, share * share * 18.0 - 4.0 * share)).round()
			draw_line(previous, at, Palette.LEAF if frond % 2 == 0 else Palette.JUNGLE)
			draw_line(previous + Vector2(0, 1), at + Vector2(0, 2), Palette.JUNGLE_DARK if frond % 2 == 0 else Palette.LEAF)
			if part % 3 == 1:
				draw_rect(Rect2(at + Vector2(0, 1), Vector2(1, 3)), Palette.LEAF_LIGHT)
			previous = at
	for nut in 3:
		draw_circle((top + Vector2(-3 + nut * 3, 3 + nut % 2)).round(), 2, Palette.MUD)


func _draw_board(footprint: Rect2) -> void:
	var front := footprint.end.y
	for post_x in [footprint.position.x + 0.05, footprint.end.x - 0.12]:
		_quad([Vector2(post_x, front), Vector2(post_x + 0.07, front)], 0.0, 1.0, Palette.BARK)
	_quad([Vector2(footprint.position.x - 0.1, front + 0.02), Vector2(footprint.end.x + 0.1, front + 0.02)], 0.45, 1.05, Palette.BARK_LIGHT)
	var top_left := World.to_screen(Vector2(footprint.position.x - 0.05, front + 0.02), 1.0)
	var freed: Array = village_record.liberated if village_record != null else []
	var ids := Areas.ids()
	for index in ids.size():
		var at := top_left + Vector2(4 + index * 7, 4 + (index % 2) * 6)
		draw_rect(Rect2(at, Vector2(4, 4)), Palette.LEAF if ids[index] in freed else Palette.HI_VIS)
		if index > 0:
			draw_line(at + Vector2(-3, 2 - (index % 2) * 6 + 3), at + Vector2(0, 2), Palette.BARK)


## The smithy: an open shed, its roof on four posts over the forge and the anvil. Restored, the
## forge glows; as a ruin, its roof has come down on one side and the hearth is cold and broken.
func _draw_smithy(footprint: Rect2, restored: bool) -> void:
	var front := footprint.end.y
	var back := footprint.position.y
	var left := footprint.position.x
	var right := footprint.end.x
	var eaves := 1.1
	var ridge := (front + back) / 2.0
	for corner in [Vector2(left, back + 0.2), Vector2(right - 0.08, back + 0.2)]:
		_quad([corner, corner + Vector2(0.08, 0.0)], 0.0, eaves if restored else eaves * 0.6, Palette.BARK)
	var hearth := Vector2(left + 0.4, ridge + 0.2)
	_quad([hearth, hearth + Vector2(0.9, 0.0)], 0.0, 0.5 if restored else 0.3, Palette.STEEL_DARK)
	if restored:
		# Coals glowing, flickering as they breathe.
		for coal in 6:
			var at := World.to_screen(hearth + Vector2(0.15 + coal * 0.11, 0.0), 0.48)
			var glow: Color = [Palette.SPARK, Palette.BRASS_LIGHT, Palette.SCARF_RED][(coal + int(_clock * 6.0)) % 3]
			draw_rect(Rect2(at, Vector2(3, 2)), glow)
	else:
		_quad([hearth + Vector2(0.15, 0.0), hearth + Vector2(0.75, 0.0)], 0.2, 0.3, Palette.BURNT)
	var block := Vector2(right - 1.0, front - 0.3)
	_quad([block, block + Vector2(0.3, 0.0)], 0.0, 0.3, Palette.BARK)
	_quad([block + Vector2(-0.1, 0.0), block + Vector2(0.4, 0.0)], 0.3, 0.42, Palette.STEEL)
	if restored:
		for corner in [Vector2(left, front), Vector2(right - 0.08, front)]:
			_quad([corner, corner + Vector2(0.08, 0.0)], 0.0, eaves, Palette.BARK_LIGHT)
		_slope(Vector2(left - 0.3, ridge), Vector2(right + 0.3, ridge), eaves + 0.75, Vector2(left - 0.3, back - 0.1), Vector2(right + 0.3, back - 0.1), eaves, THATCH[1])
		_slope(Vector2(left - 0.3, ridge), Vector2(right + 0.3, ridge), eaves + 0.75, Vector2(left - 0.3, front + 0.15), Vector2(right + 0.3, front + 0.15), eaves - 0.05, THATCH[0])
		_thatch(left - 0.3, right + 0.3, ridge, eaves + 0.75, front + 0.15, eaves - 0.05)
		_bunting(left - 0.2, right + 0.2, front + 0.15, eaves - 0.17)
	else:
		# The roof slid off its front posts and lies against the ground.
		_slope(Vector2(left - 0.2, back + 0.2), Vector2(right + 0.2, back + 0.2), eaves * 0.6, Vector2(left - 0.1, front + 0.3), Vector2(right + 0.3, front + 0.2), 0.0, Palette.BARK)
		_thatch(left - 0.2, right + 0.2, back + 0.2, eaves * 0.6, front + 0.25, 0.0, OLD_THATCH)


## Jogiboy: his own drawing, facing the way he's going (or toward Tompel, standing). He trots,
## never gallops: legs reaching and gathering in turn, every foot on the ground, the stride long
## enough that his legs keep up with the ground he covers. Standing, his legs are under him.
func _draw_jogi(jogi: Cat) -> void:
	var moving := jogi.body.velocity.length() > 0.1
	if moving and absf(jogi.body.velocity.x) > 0.3:
		jogi.facing = Vector2(signf(jogi.body.velocity.x), 0.0)
	var facing_left := jogi.facing.x < 0.0
	var frame := JOGI_TROT[int(_walked.get(jogi, 0.0) / JOGI_STRIDE * JOGI_TROT.size()) % JOGI_TROT.size()] if moving else 1
	if village.jogi_digging:
		# Digging: his paws going, and the dirt flying out behind him.
		frame = JOGI_TROT[int(_clock * 10.0) % 2]
		var behind := World.to_screen(jogi.body.position) + Vector2(10 if facing_left else -10, -2)
		for fleck in 5:
			var arc := fmod(_clock * 3.0 + fleck * 0.37, 1.0)
			var out := Vector2((1 if facing_left else -1) * (arc * 9.0 + fleck), -sin(arc * PI) * 7.0)
			draw_rect(Rect2((behind + out).round(), Vector2.ONE), Palette.MUD_LIGHT if fleck % 2 else Palette.MUD_DARK)
	var texture := Sprites.lit(Sprites.jogi_art(frame), facing_left)
	var feet := Sprites.JOGI_FEET
	if facing_left:
		feet.x = texture.get_width() - 1 - feet.x
	var corner := World.to_screen(jogi.body.position) - feet
	# His shadow under him, a dog's length.
	draw_rect(Rect2(World.to_screen(jogi.body.position) + Vector2(-9, -1), Vector2(18, 3)), Palette.GROUND_SHADOW)
	draw_texture(texture, corner)


## Jingga's watchtower: four bamboo posts up to a lookout platform, a ladder, and a little thatched
## roof over it. A ruin is its posts snapped short and the platform down in the grass.
func _draw_watchtower(footprint: Rect2, restored: bool) -> void:
	var left := footprint.position.x + 0.15
	var right := footprint.end.x - 0.15
	var back := footprint.position.y + 0.15
	var front := footprint.end.y - 0.15
	var deck := 1.9 if restored else 0.0
	var posts: Array[Vector2] = [Vector2(left, back), Vector2(right - 0.08, back), Vector2(left, front), Vector2(right - 0.08, front)]
	for index in posts.size():
		var post: Vector2 = posts[index]
		var height: float = deck + 0.5 if restored else [0.9, 0.5, 0.7, 0.35][index]
		_quad([post, post + Vector2(0.08, 0.0)], 0.0, height, Palette.DRY_GRASS if index >= 2 else Palette.MOSS)
	if not restored:
		# The platform, fallen flat, and its ladder beside it.
		_slope(Vector2(left - 0.3, front + 0.1), Vector2(right + 0.2, front + 0.2), 0.02, Vector2(left - 0.2, front + 0.6), Vector2(right + 0.3, front + 0.7), 0.02, Palette.BARK)
		for rung in 4:
			_quad([Vector2(right + 0.3, front + 0.2 + rung * 0.12), Vector2(right + 0.6, front + 0.2 + rung * 0.12)], 0.0, 0.03, Palette.DRY_GRASS)
		return
	# The ladder up the front, rung by rung.
	var ladder := Vector2((left + right) / 2.0 - 0.15, front + 0.02)
	_quad([ladder, ladder + Vector2(0.03, 0.0)], 0.0, deck, Palette.BARK_LIGHT)
	_quad([ladder + Vector2(0.3, 0.0), ladder + Vector2(0.33, 0.0)], 0.0, deck, Palette.BARK_LIGHT)
	for rung in 6:
		_quad([ladder, ladder + Vector2(0.33, 0.0)], 0.25 + rung * 0.28, 0.29 + rung * 0.28, Palette.BARK_LIGHT)
	# The deck, its rail, and the roof over it.
	_slope(Vector2(left - 0.1, back - 0.1), Vector2(right + 0.1, back - 0.1), deck, Vector2(left - 0.1, front + 0.1), Vector2(right + 0.1, front + 0.1), deck, Palette.BARK)
	_quad([Vector2(left - 0.1, front + 0.1), Vector2(right + 0.1, front + 0.1)], deck, deck + 0.3, Palette.BARK_LIGHT)
	var middle := (back + front) / 2.0
	_slope(Vector2(left - 0.2, middle), Vector2(right + 0.2, middle), deck + 1.0, Vector2(left - 0.25, front + 0.25), Vector2(right + 0.25, front + 0.25), deck + 0.5, Palette.DRY_GRASS)
	_thatch(left - 0.25, right + 0.25, middle, deck + 1.0, front + 0.25, deck + 0.5)


## Kopi and Susu's stall: posts under a striped awning, and a counter heaped with fruit, facing the
## road. A ruin is the awning torn down over the counter's broken boards. With him at the counter,
## the awning is drawn back, so it doesn't hide him.
func _draw_market(footprint: Rect2, restored: bool, drawn_back := false) -> void:
	var left := footprint.position.x + 0.1
	var right := footprint.end.x - 0.1
	var back := footprint.position.y + 0.1
	var front := footprint.end.y - 0.1
	var awning := 1.2 if restored else 0.5
	# The counter stands on the road side, its back to us: the tall posts at the stall's back, ours.
	var counter := back + 0.3
	for post: Vector2 in [Vector2(left, back), Vector2(right - 0.08, back)]:
		_quad([post, post + Vector2(0.08, 0.0)], 0.0, awning if restored else awning * 0.5, Palette.BARK)
	# The counter: boards along the road side, broken through in a ruin.
	if restored:
		_quad([Vector2(left, counter), Vector2(right, counter)], 0.0, 0.5, Palette.BARK)
		_quad([Vector2(left - 0.05, counter), Vector2(right + 0.05, counter)], 0.5, 0.56, Palette.BARK_LIGHT)
		# Fruit heaped on it, a few colors, the same every time.
		var random := RandomNumberGenerator.new()
		random.seed = 11
		for fruit in 16:
			var at := World.to_screen(Vector2(random.randf_range(left + 0.15, right - 0.15), counter + 0.02), 0.58 + random.randf_range(0.0, 0.08))
			draw_rect(Rect2(at.round(), Vector2(2, 2)), [Palette.HI_VIS, Palette.LEAF_LIGHT, Palette.BRASS_LIGHT, Palette.SCARF_RED][fruit % 4])
	else:
		_quad([Vector2(left, counter), Vector2(left + 0.8, counter)], 0.0, 0.35, Palette.BARK)
		_quad([Vector2(right - 0.6, counter), Vector2(right, counter)], 0.0, 0.2, Palette.BARK)
	# Crates stacked behind the counter, our side of it.
	if restored:
		for crate in 2:
			var at := Vector2(left + 0.3 + crate * 1.1, front - 0.35)
			_quad([at, at + Vector2(0.4, 0.0)], 0.0, 0.3, Palette.BARK_LIGHT)
			_quad([at + Vector2(0.05, 0.0), at + Vector2(0.35, 0.0)], 0.12, 0.16, Palette.BARK)
	for post: Vector2 in [Vector2(left, front), Vector2(right - 0.08, front)]:
		_quad([post, post + Vector2(0.08, 0.0)], 0.0, awning + 0.25, Palette.BARK_LIGHT)
	if drawn_back and restored:
		return
	# The awning in stripes, sloping down toward the counter, over the stall; fallen flat in a
	# ruin, torn through in places.
	var stripes := 8
	for stripe in stripes:
		if not restored and stripe % 3 == 1:
			continue
		var from := lerpf(left - 0.1, right + 0.1, float(stripe) / stripes)
		var to := lerpf(left - 0.1, right + 0.1, float(stripe + 1) / stripes)
		var color := Palette.SCARF_RED if stripe % 2 == 0 else Palette.CREAM
		if restored:
			_slope(Vector2(from, back + 0.45), Vector2(to, back + 0.45), awning, Vector2(from, front + 0.05), Vector2(to, front + 0.05), awning + 0.3, color)
		else:
			_slope(Vector2(from, back + 0.1), Vector2(to, back + 0.1), 0.25, Vector2(from, front + 0.1), Vector2(to, front + 0.1), 0.02, color)


## Bu Jamu's pots of herbs out front of the healer's hut: turmeric, ginger and lemongrass growing,
## or knocked over in the ruin.
func _draw_herbs(footprint: Rect2, restored: bool) -> void:
	for index in 3:
		var pot := Vector2(footprint.position.x + 0.3 + index * 0.6, footprint.end.y + 0.25)
		if restored:
			_quad([pot, pot + Vector2(0.25, 0.0)], 0.0, 0.18, Palette.MUD_LIGHT)
			var at := World.to_screen(pot + Vector2(0.12, 0.0), 0.2)
			for leaf in 4:
				draw_rect(Rect2((at + Vector2(-3 + leaf * 2, -2 - leaf % 2 * 2)).round(), Vector2(1, 3)), Palette.LEAF if index != 1 else Palette.BRASS_LIGHT)
		else:
			_slope(pot, pot + Vector2(0.25, 0.0), 0.05, pot + Vector2(0.05, 0.12), pot + Vector2(0.3, 0.12), 0.0, Palette.MUD_LIGHT)


## An umbul-umbul: a tall bamboo pole bowed at its tip, its long banner hanging in bands of color
## and stirring in the air. Until the longhouse is restored, a snapped stump with its banner in the
## mud.
func _draw_flag(foot: Vector2, restored: bool) -> void:
	var base := World.to_screen(foot)
	if not restored:
		draw_line(base, base + Vector2(1, -14), Palette.DRY_GRASS)
		draw_line(base + Vector2(2, 0), base + Vector2(14, -2), Palette.SCARF_RED)
		draw_line(base + Vector2(2, 1), base + Vector2(12, -1), Palette.BRASS)
		return
	var top := base + Vector2(0, -88)
	draw_line(base, top, Palette.DRY_GRASS)
	draw_line(base + Vector2(1, 0), top + Vector2(1, 2), Palette.MOSS)
	# The tip bows over, and the banner hangs from it.
	var tip := top + Vector2(6, 3)
	draw_line(top, tip, Palette.DRY_GRASS)
	var colors: Array = BANNERS.get(banners, BANNERS.festival)
	for band in 14:
		var sway := roundf(sin(_clock * 2.0 + band * 0.4 + foot.x) * minf(band * 0.4, 3.0))
		draw_rect(Rect2(tip + Vector2(-2 + sway, 1 + band * 4), Vector2(4, 4)), colors[band / 3 % colors.size()])


## Flowers in the grass about a restored building, in the same places every time.
func _draw_flowers(footprint: Rect2) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = hash(footprint)
	var colors: Array[Color] = [Palette.PINK, Palette.BRASS_LIGHT, Palette.CREAM, Palette.SCARF_RED]
	for flower in 10:
		var side := random.randf() < 0.5
		var spot := Vector2(
			footprint.position.x - 0.3 if side else footprint.end.x + 0.3,
			random.randf_range(footprint.position.y + 0.2, footprint.end.y + 0.3)) + Vector2(random.randf_range(-0.25, 0.25), 0.0)
		var at := World.to_screen(spot)
		draw_rect(Rect2(at + Vector2(0, 1), Vector2(1, 2)), Palette.LEAF)
		draw_rect(Rect2(at, Vector2(1, 1)), colors[random.randi_range(0, colors.size() - 1)])


## The longhouse's painted band: a zigzag in red and yellow along the wall.
func _band(left: float, right: float, front: float, height: float) -> void:
	var x := left
	var up := true
	while x < right - 0.1:
		var from := World.to_screen(Vector2(x, front), height + (0.0 if up else 0.12))
		var to := World.to_screen(Vector2(x + 0.12, front), height + (0.12 if up else 0.0))
		draw_line(from, to, Palette.SCARF_RED)
		draw_line(from + Vector2(0, 2), to + Vector2(0, 2), Palette.BRASS)
		x += 0.12
		up = not up


## Bunting under the eaves: little flags in turn, stirring in the air.
func _bunting(left: float, right: float, eave: float, height: float) -> void:
	var x := left + 0.1
	var index := 0
	while x < right - 0.1:
		var at := World.to_screen(Vector2(x, eave), height) + Vector2(0, 2)
		var sway := 1 if (int(_clock * 2.0) + index) % 4 == 0 else 0
		draw_colored_polygon(PackedVector2Array([at, at + Vector2(4, 0), at + Vector2(2 + sway, 4)]), PAINTS[index % PAINTS.size()])
		x += 0.16
		index += 1


## Palm thatch on a front slope, laid in courses from the eave up: each course a row of scallops
## hanging over the one below, catching the light along its top; the ridge capped in a fat roll;
## and the eave a scalloped edge with its shadow on the wall under it. Gold and fresh unless told
## otherwise (OLD_THATCH, on a ruin).
func _thatch(left: float, right: float, ridge: float, peak: float, eave: float, eave_height: float, colors: Array = THATCH) -> void:
	var body: Color = colors[0]
	var shade: Color = colors[1]
	var light: Color = colors[2]
	var line: Color = Palette.MUD if colors == THATCH else Palette.BURNT
	var courses := 4
	for course in range(1, courses):
		var share := float(course) / courses
		var from := World.to_screen(Vector2(left, lerpf(eave, ridge, share)), lerpf(eave_height, peak, share))
		var to := World.to_screen(Vector2(right, lerpf(eave, ridge, share)), lerpf(eave_height, peak, share))
		# Each scallop a cupped edge, every other course set over by half a scallop.
		var x := from.x + 1 + (4 if course % 2 == 0 else 0)
		while x < to.x - 8:
			draw_rect(Rect2(Vector2(x, from.y - 1), Vector2.ONE), line)
			draw_rect(Rect2(Vector2(x + 1, from.y), Vector2.ONE), line)
			draw_rect(Rect2(Vector2(x + 2, from.y + 1), Vector2(4, 1)), line)
			draw_rect(Rect2(Vector2(x + 6, from.y), Vector2.ONE), line)
			draw_rect(Rect2(Vector2(x + 7, from.y - 1), Vector2.ONE), line)
			draw_rect(Rect2(Vector2(x + 2, from.y - 1), Vector2(4, 1)), shade)
			draw_rect(Rect2(Vector2(x + 2, from.y - 5), Vector2(3, 1)), light)
			x += 8
	# The light falls on the roof's left edge, from the top left.
	draw_line(World.to_screen(Vector2(left, ridge), peak), World.to_screen(Vector2(left, eave), eave_height), light)
	var ridge_left := World.to_screen(Vector2(left, ridge), peak)
	var ridge_right := World.to_screen(Vector2(right, ridge), peak)
	draw_rect(Rect2(ridge_left + Vector2(0, -2), Vector2(ridge_right.x - ridge_left.x, 4)), shade)
	draw_rect(Rect2(ridge_left + Vector2(1, -2), Vector2(ridge_right.x - ridge_left.x - 2, 1)), light)
	draw_circle(ridge_left, 2, shade)
	draw_circle(ridge_right, 2, shade)
	var eave_left := World.to_screen(Vector2(left, eave), eave_height)
	var eave_right := World.to_screen(Vector2(right, eave), eave_height)
	draw_rect(Rect2(eave_left + Vector2(2, 4), Vector2(eave_right.x - eave_left.x - 4, 2)), Palette.JUNGLE_DARK)
	var x := eave_left.x + 4
	while x <= eave_right.x - 4:
		draw_circle(Vector2(x, eave_left.y + 1), 4, line)
		draw_circle(Vector2(x, eave_left.y), 4, body)
		draw_rect(Rect2(Vector2(x - 2, eave_left.y - 2), Vector2(2, 1)), light)
		x += 8


## A flat upright face along the ground from one point to another, from one height to another.
func _quad(along: Array, bottom: float, top: float, color: Color) -> void:
	var a: Vector2 = along[0]
	var b: Vector2 = along[1]
	draw_colored_polygon(PackedVector2Array([World.to_screen(a, bottom), World.to_screen(b, bottom), World.to_screen(b, top), World.to_screen(a, top)]), color)


## A roof slope from its ridge, at one height, down to its eave, at another.
func _slope(ridge_left: Vector2, ridge_right: Vector2, ridge_height: float, eave_left: Vector2, eave_right: Vector2, eave_height: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		World.to_screen(ridge_left, ridge_height), World.to_screen(ridge_right, ridge_height),
		World.to_screen(eave_right, eave_height), World.to_screen(eave_left, eave_height),
	]), color)
