class_name CanopyView
extends Node2D
## The canopy overhead: the crowns of the trees at the clearing's edge, and leaves hanging out
## over it from the jungle around, thinning toward the middle. It's above everyone's heads, so nothing collides with it, and it's drawn
## over everything. The lights don't touch it: it's the shade.

var _clusters: Array[Dictionary] = []
## Everything overhead that never changes, the edge's crowns and the hanging leaves, put together
## into one picture; and how far past the place it reaches, in pixels.
var _overhead: ImageTexture
const MARGIN := 260
## The ground, whose edge trees' crowns hang here with the rest of the leaves.
var ground: GroundView


func _ready() -> void:
	light_mask = 0
	if ground != null:
		ground.planted.connect(_hang)
	_hang()


## The leaves hanging in from the jungle all round, at the edge of however big the place is.
func _hang() -> void:
	_clusters.clear()
	var random := RandomNumberGenerator.new()
	random.seed = 11
	var size := (ground.meters if ground != null else Arena.SIZE) * World.PIXELS_PER_METER
	for index in 160:
		var side := random.randi_range(0, 3)
		var reach := absf(random.randfn(0.0, 34.0))
		var center: Vector2
		match side:
			0: center = Vector2(random.randf() * size.x, -14.0 + reach)
			1: center = Vector2(size.x + 14.0 - reach, random.randf() * size.y)
			2: center = Vector2(random.randf() * size.x, size.y + 14.0 - reach)
			_: center = Vector2(-14.0 + reach, random.randf() * size.y)
		var picture := EnvironmentArt.leaves(random.randi_range(12, 24), random.randi(), random.randf() < 0.65)
		_clusters.append({"texture": ImageTexture.create_from_image(picture), "at": (center - Vector2(picture.get_size()) / 2.0).round()})
	var overhead := Image.create_empty(int(size.x) + MARGIN * 2, int(size.y) + MARGIN * 2, false, Image.FORMAT_RGBA8)
	var pieces: Array = _clusters.duplicate()
	if ground != null:
		pieces = ground.crowns.filter(func(crown: Dictionary) -> bool: return not crown.get("over_the_fight", false)) + pieces
	for piece: Dictionary in pieces:
		var part: Image = piece.texture.get_image()
		part.convert(Image.FORMAT_RGBA8)
		overhead.blend_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), Vector2i(piece.at) + Vector2i.ONE * MARGIN)
	_overhead = ImageTexture.create_from_image(overhead)
	queue_redraw()


## A crown over the fight, not at its edge, thins while a cat is under it, so he's never lost, or
## a cage still shut, so the caged are never hidden.
const THINNED := Color(1.0, 1.0, 1.0, 0.4)


func _process(_delta: float) -> void:
	if ground != null and ground.crowns.any(func(crown: Dictionary) -> bool: return crown.get("over_the_fight", false)):
		queue_redraw()


func _draw() -> void:
	draw_texture(_overhead, -Vector2.ONE * MARGIN)
	if ground != null:
		for crown in ground.crowns:
			if not crown.get("over_the_fight", false):
				continue
			var tint := Color.WHITE
			if ground.arena != null:
				var covers := Rect2(crown.at, crown.texture.get_size())
				for cat in ground.arena.cats:
					if covers.has_point(World.to_screen(cat.body.position, 0.2)):
						tint = THINNED
				for cage in ground.arena.cages:
					if not cage.opened and covers.has_point(World.to_screen(cage.body.position, 0.25)):
						tint = THINNED
			draw_texture(crown.texture, crown.at, tint)
