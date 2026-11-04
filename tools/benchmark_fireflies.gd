extends SceneTree
## What fireflies left lying about cost: one simulation step with a crushed horde around a cat on
## the move, and the view's pass over them to find those on screen, with none out and with many.
## Run with:
## timeout 300 godot --headless --path . --script tools/benchmark_fireflies.gd

const COUNTS: Array[int] = [0, 1000, 5000, 20000]
const HORDE := 600
const STEPS := 300


func _init() -> void:
	print("Arena %s m, a horde of %d crushed round him" % [Arena.SIZE, HORDE])
	for count in COUNTS:
		var arena := Arena.new()
		arena.spawning = false
		var cat := arena.add_cat(Arena.SIZE / 2.0)
		cat.health = 1.0e9
		for index in HORDE:
			arena.add_creature(arena.edge_point() * 0.7 + arena.size * 0.15)
		for step in 60 * 12:
			_refill(arena)
			arena.step()
		# Scattered over the clearing, away from him, as a long run leaves them.
		var dice := RandomNumberGenerator.new()
		dice.seed = 39
		for index in count:
			var spot := Vector2(dice.randf() * Arena.SIZE.x, dice.randf() * Arena.SIZE.y)
			if spot.distance_to(cat.body.position) > 4.0:
				arena.fireflies.rise(spot, 1, arena.time)
		var started := Time.get_ticks_usec()
		for step in STEPS:
			_refill(arena)
			cat.steering = Vector2.from_angle(step * 0.02)
			arena.step()
		var step_ms := (Time.get_ticks_usec() - started) / 1000.0 / STEPS
		started = Time.get_ticks_usec()
		var shown := 0
		for frame in 60:
			shown = _on_screen(arena, cat.body.position)
		var view_ms := (Time.get_ticks_usec() - started) / 1000.0 / 60
		var world := Snapshot.take(arena, [])
		var bytes := Snapshot.Sender.new().delta(world).size()
		print("%6d fireflies (%5d out, %4d on screen): %.2f ms a step, %.2f ms to find those on screen, %d bytes to a guest joining" % [count, arena.fireflies.count(), shown, step_ms, view_ms, bytes])
	quit()


## The view's pass, without drawing: those in the grid's cells on a 640 by 360 screen, counted.
func _on_screen(arena: Arena, around: Vector2) -> int:
	var seen := Rect2(World.to_screen(around) - Vector2(320, 180), Vector2(640, 360))
	var area := Rect2(seen.position / World.PIXELS_PER_METER, seen.size / World.PIXELS_PER_METER).grow(1.0)
	var lights := arena.fireflies
	var shown := 0
	for slot in lights.within(area):
		if seen.grow(40.0).has_point(World.to_screen(lights.at[slot])):
			shown += 1
	return shown


func _refill(arena: Arena) -> void:
	while arena.creatures.size() < HORDE:
		arena.add_creature(arena.edge_point())
