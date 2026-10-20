class_name Creature
extends RefCounted
## One of the horde: for now, a rat from the company's supply crates. Runs at the nearest cat
## and bites.

const SPEED := 1.7
## How fast it gets back up to speed, or turns, in meters a second each second.
const GRIP := 12.0
const BITE_DAMAGE := 1.0
const BITE_INTERVAL := 0.8

var body := Body.new()
var health := 2.0
## Experience its fall is worth to the crew.
var worth := 1
var bite_ready_in := 0.0


func _init() -> void:
	body.radius = 0.08
	body.tall = 0.1


func alive() -> bool:
	return health > 0.0


func step(delta: float, prey: Cat) -> void:
	bite_ready_in = maxf(bite_ready_in - delta, 0.0)
	if not body.airborne():
		var wanted := Vector2.ZERO
		if prey != null and prey.alive():
			wanted = (prey.body.position - body.position).normalized() * SPEED
		# Feet on the ground: it claws back to the pace it wants, so a knock carries it a way.
		body.velocity = body.velocity.move_toward(wanted, GRIP * delta)
	body.step(delta)
