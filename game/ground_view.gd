class_name GroundView
extends Node2D
## The clearing and the jungle around it: the ground, the grass and ferns growing over it, and
## the trees and big leaves at its edge. No outlines: the environment stays behind the
## characters.

## How far past the clearing the jungle is drawn, in pixels.
const JUNGLE_DEPTH := 400.0
## How many tufts and ferns grow in the clearing, and how close a body must pass to bend one, in
## meters.
const GROWTH := 900
const BRUSH_REACH := 0.08

var arena: Arena
var _ground: ImageTexture
var _growth: Array[Dictionary] = []
var _edge: Array[Dictionary] = []
var _upright := {}
var _bent := {}


func _ready() -> void:
	var size := Vector2i(Arena.SIZE * World.PIXELS_PER_METER)
	_ground = ImageTexture.create_from_image(EnvironmentArt.ground(size, 39))
	for kind in ["tuft", "fern"]:
		for lean in [-1, 0, 1]:
			var picture: Image = EnvironmentArt.tuft(lean) if kind == "tuft" else EnvironmentArt.fern(lean)
			var texture := ImageTexture.create_from_image(picture)
			if lean == 0:
				_upright[kind] = texture
			else:
				_bent["%s%d" % [kind, lean]] = texture
	var random := RandomNumberGenerator.new()
	random.seed = 5
	for index in GROWTH:
		var where := Vector2(random.randf() * Arena.SIZE.x, random.randf() * Arena.SIZE.y)
		_growth.append({"position": where, "kind": "fern" if random.randf() < 0.25 else "tuft"})
	_plant_edge(random)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var clearing := Rect2(Vector2.ZERO, Arena.SIZE * World.PIXELS_PER_METER)
	draw_rect(clearing.grow(JUNGLE_DEPTH), Palette.JUNGLE_DEEP)
	draw_texture(_ground, Vector2.ZERO)
	var view := _visible_meters()
	for plant in _growth:
		var where: Vector2 = plant.position
		if not view.has_point(where):
			continue
		var lean := arena.brushing(where, BRUSH_REACH) if arena != null else 0
		var texture: Texture2D = _upright[plant.kind] if lean == 0 else _bent["%s%d" % [plant.kind, lean]]
		draw_texture(texture, World.to_screen(where) - Vector2(texture.get_width() / 2, texture.get_height() - 1))
	for piece in _edge:
		draw_texture(piece.texture, piece.at)


## The part of the clearing on screen, in meters, with a margin.
func _visible_meters() -> Rect2:
	var screen := get_viewport_rect().size
	var center := get_viewport().get_camera_2d().get_screen_center_position() if get_viewport().get_camera_2d() != null else Vector2.ZERO
	return Rect2((center - screen / 2.0) / World.PIXELS_PER_METER, screen / World.PIXELS_PER_METER).grow(0.5)


## Trees stand just outside the clearing, with big leaves and undergrowth in front of their feet.
func _plant_edge(random: RandomNumberGenerator) -> void:
	var size := Arena.SIZE * World.PIXELS_PER_METER
	var perimeter := 2.0 * (size.x + size.y)
	var along := 0.0
	var trees: Array[Dictionary] = []
	var front: Array[Dictionary] = []
	while along < perimeter:
		along += random.randf_range(40.0, 90.0)
		var point := _on_edge(along, size)
		var outward := _outward(along, size)
		var height := random.randi_range(70, 120)
		var picture := EnvironmentArt.trunk(height, random.randi_range(8, 14), random.randi())
		var foot := point + outward * random.randf_range(14.0, 40.0)
		trees.append({"texture": ImageTexture.create_from_image(picture), "at": (foot - Vector2(picture.get_width() / 2, height)).round(), "y": foot.y})
	along = 0.0
	while along < perimeter:
		along += random.randf_range(10.0, 20.0)
		var point := _on_edge(along, size)
		var outward := _outward(along, size)
		var picture: Image
		if random.randf() < 0.35:
			picture = EnvironmentArt.banana_leaf(random.randi_range(26, 40), random.randi())
			if random.randf() < 0.5:
				picture.flip_x()
		else:
			picture = EnvironmentArt.leaves(random.randi_range(9, 16), random.randi(), random.randf() < 0.5)
		var at := point + outward * random.randf_range(0.0, 12.0)
		front.append({"texture": ImageTexture.create_from_image(picture), "at": (at - Vector2(picture.get_size()) / 2.0).round(), "y": at.y})
	trees.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.y < b.y)
	_edge.append_array(trees)
	_edge.append_array(front)


func _on_edge(along: float, size: Vector2) -> Vector2:
	if along < size.x:
		return Vector2(along, 0.0)
	along -= size.x
	if along < size.y:
		return Vector2(size.x, along)
	along -= size.y
	if along < size.x:
		return Vector2(size.x - along, size.y)
	return Vector2(0.0, size.y - (along - size.x))


func _outward(along: float, size: Vector2) -> Vector2:
	if along < size.x:
		return Vector2.UP
	if along < size.x + size.y:
		return Vector2.RIGHT
	if along < 2.0 * size.x + size.y:
		return Vector2.DOWN
	return Vector2.LEFT
