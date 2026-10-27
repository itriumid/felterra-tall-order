extends SceneTree
## How long one simulation step takes with a horde of a given size around a cat, so we know
## what GDScript can carry. Run with:
## timeout 300 godot --headless --path . --script tools/benchmark_horde.gd
## and add `-- --area=<id>` for a liberation area's ground plan, him on the move through it, so
## the way around what stands there is found again and again.

const SIZES: Array[int] = [100, 300, 600, 1000]
const STEPS := 300


func _init() -> void:
	var area := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--area="):
			area = argument.get_slice("=", 1)
	for size in SIZES:
		var arena := Arena.new()
		arena.spawning = false
		if not area.is_empty():
			arena.begin_area(area)
		var cat := arena.add_cat(arena.area.get("start", arena.size / 2.0))
		cat.health = 1.0e9
		for index in size:
			arena.add_creature(arena.edge_point() * 0.7 + arena.size * 0.15)
		# Let them close in fully: the crush around the cat is the worst case, and what counts.
		for step in 60 * 12:
			_refill(arena, size)
			arena.step()
		var started := Time.get_ticks_usec()
		for step in STEPS:
			_refill(arena, size)
			if not area.is_empty():
				cat.steering = Vector2.from_angle(step * 0.02)
			arena.step()
		var milliseconds := (Time.get_ticks_usec() - started) / 1000.0 / STEPS
		print("%5d creatures: %.2f ms a step (%.0f%% of a 60 Hz frame)" % [size, milliseconds, milliseconds / 16.67 * 100.0])
	quit()


## The gun thins the horde; topping it back up keeps the count honest.
func _refill(arena: Arena, size: int) -> void:
	while arena.creatures.size() < size:
		arena.add_creature(arena.edge_point())
