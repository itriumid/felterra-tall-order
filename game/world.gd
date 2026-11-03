class_name World
extends RefCounted
## Where the simulation's meters meet the screen's pixels.

## A cat about 45 centimeters tall is 18 pixels; a human, 70.
const PIXELS_PER_METER := 40.0


## A shift of less than a pixel added to every point before it's rounded, while one big thing made
## of many parts is drawn (a machine): set so the thing's middle falls on a whole pixel, every part
## keeps the same fraction of a pixel as it moves, so all of it steps to the next pixel together,
## instead of each corner and joint stepping on a different frame and the parts shivering apart.
static var snap := Vector2.ZERO


static func to_screen(position: Vector2, height := 0.0) -> Vector2:
	return (position * PIXELS_PER_METER - Vector2(0.0, height * PIXELS_PER_METER) + snap).round()


## Snaps what's drawn next to move as one with a body at this spot; unsnap() after.
static func snap_to(position: Vector2) -> void:
	var exact := position * PIXELS_PER_METER
	snap = exact.round() - exact


static func unsnap() -> void:
	snap = Vector2.ZERO
