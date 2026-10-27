class_name Obstacle
extends RefCounted
## Something that stands in an area and doesn't move: a tree's trunk, a stump, a stack of logs, a
## cabin, a hangar. Round or a box on the ground, and as tall as it is: nothing walks through it,
## a round flying lower than its top stops in it, and a cat in the air above it passes over.

## Each kind: how tall it stands, in meters, and whether it's round (a trunk, a stump, a rock) or a
## box (a stack, a cabin).
const KINDS := {
	"tree": {"tall": 6.0, "round": true},
	"stump": {"tall": 0.35, "round": true},
	"bush": {"tall": 0.7, "round": true},
	"rock": {"tall": 0.9, "round": true},
	"trunk": {"tall": 0.5, "round": false},
	"log_stack": {"tall": 1.3, "round": false},
	"cabin": {"tall": 2.4, "round": false},
	"crates": {"tall": 1.0, "round": false},
	"hangar": {"tall": 3.2, "round": false},
	"tank": {"tall": 1.6, "round": true},
	# Where nothing goes at all: a building's walls, the forest off the path.
	"wall": {"tall": 9.0, "round": false},
	# A river's edge: nothing walks into it, and everything flies over it. The giants and the
	# machines wade.
	"water": {"tall": 0.05, "round": false},
}

var kind := ""
var tall := 0.0
## A box's footprint on the ground; a round one's center and radius.
var rect := Rect2()
var center := Vector2.ZERO
var radius := 0.0


## One from a layout's entry: {kind, at, radius} for a round one, {kind, rect} for a box.
static func from(entry: Dictionary) -> Obstacle:
	var obstacle := Obstacle.new()
	obstacle.kind = entry.kind
	obstacle.tall = KINDS[entry.kind].tall
	if KINDS[entry.kind].round:
		obstacle.center = entry.at
		obstacle.radius = entry.radius
		obstacle.rect = Rect2(obstacle.center - Vector2.ONE * obstacle.radius, Vector2.ONE * obstacle.radius * 2.0)
	else:
		obstacle.rect = entry.rect
		obstacle.center = obstacle.rect.get_center()
	return obstacle


func is_round() -> bool:
	return KINDS[kind].round


## Whether a point is inside it, or within a margin of it.
func contains(where: Vector2, margin := 0.0) -> bool:
	if is_round():
		return where.distance_to(center) < radius + margin
	return rect.grow(margin).has_point(where)


## Whether any of a square of ground comes within a margin of it.
func overlaps(area: Rect2, margin := 0.0) -> bool:
	if is_round():
		var nearest := center.clamp(area.position, area.end)
		return nearest.distance_to(center) < radius + margin
	return rect.grow(margin).intersects(area)


## The point nearest a point that's outside it, by a margin: pushed out the shortest way.
func push_out(where: Vector2, margin: float) -> Vector2:
	if is_round():
		var apart := where - center
		var reach := radius + margin
		if apart.length() >= reach:
			return where
		return center + (apart.normalized() if apart.length() > 0.001 else Vector2.UP) * reach
	var grown := rect.grow(margin)
	if not grown.has_point(where):
		return where
	var to_left := where.x - grown.position.x
	var to_right := grown.end.x - where.x
	var to_top := where.y - grown.position.y
	var to_bottom := grown.end.y - where.y
	var least := minf(minf(to_left, to_right), minf(to_top, to_bottom))
	if least == to_left:
		return Vector2(grown.position.x, where.y)
	if least == to_right:
		return Vector2(grown.end.x, where.y)
	if least == to_top:
		return Vector2(where.x, grown.position.y)
	return Vector2(where.x, grown.end.y)


## How far along a segment, as a share of it, it first meets this, grown by a margin: INF if it
## doesn't. A segment starting inside meets it at once.
func crossing(from: Vector2, to: Vector2, margin := 0.0) -> float:
	if contains(from, margin):
		return 0.0
	if is_round():
		var hit: Variant = Geometry2D.segment_intersects_circle(from, to, center, radius + margin)
		return hit if hit != null and hit >= 0.0 else INF
	var grown := rect.grow(margin)
	var along := to - from
	var enter := 0.0
	var leave := 1.0
	for axis in 2:
		var start := from[axis]
		var span := along[axis]
		var low := grown.position[axis]
		var high := grown.end[axis]
		if absf(span) < 0.000001:
			if start < low or start > high:
				return INF
			continue
		var first := (low - start) / span
		var second := (high - start) / span
		if first > second:
			var swap := first
			first = second
			second = swap
		enter = maxf(enter, first)
		leave = minf(leave, second)
		if enter > leave:
			return INF
	return enter
