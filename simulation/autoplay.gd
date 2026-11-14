class_name Autoplay
extends RefCounted
## A simple player, for trying the game without playing it: the late start's levels are chosen by
## it, and tools/simulate_endless.gd plays whole runs with it. It plays the way a player who's
## found a weapon they like does: everything for the weapons in its paws first (their levels, their
## evolutions, damage and speed for their bonuses), then gear, then anything. And it steers away
## from what's close, off the giants and machines, toward the fireflies, keeping off the edge.
##
## It's worse than a person at all of it, and it's tuning's floor, never its ceiling: a run it
## survives, a player should.


## Which choice of an offer it plays.
static func choose(cat: Cat, offer: Array) -> int:
	var best := 0
	var best_score := -INF
	for index in offer.size():
		var score := _score(cat, offer[index])
		if score > best_score:
			best_score = score
			best = index
	return best


static func _score(cat: Cat, choice: Dictionary) -> float:
	var id: String = choice.id
	var rarity: float = choice.get("rarity", 0)
	if id.begins_with("bonus:"):
		return {"damage": 9.0, "speed": 8.5, "pierce": 7.0, "more": 7.0, "crit": 6.0}.get(id.get_slice(":", 2), 5.0)
	if id.begins_with("evolve:") or id.begins_with("level:") or id.begins_with("mastery:"):
		return 8.0 + rarity * 0.2
	if id.begins_with("gear"):
		return 4.0 + rarity
	if id.begins_with("weapon:"):
		# A first weapon, or a second one while the tail's still empty.
		return 10.0 if cat.weapons.size() < 2 else 3.0
	if id.begins_with("support"):
		return 3.5 + rarity * 0.5
	return 2.0 + rarity


## Plays every offer it's holding.
static func play_all(cat: Cat) -> void:
	while not cat.offers.is_empty():
		cat.play(choose(cat, cat.offers[0]))


## Where it steers: away from what's close (the closer, the harder), well away from a giant or a
## machine, toward the nearest firefly, and back toward the middle the nearer the edge it gets.
static func steer(cat: Cat, arena: Arena) -> Vector2:
	var here := cat.body.position
	var steering := Vector2.ZERO
	for target: Object in arena.targets_near(here, 3.0):
		var apart: Vector2 = here - target.body.position
		steering += apart.normalized() / maxf(apart.length_squared(), 0.02)
	for giant in arena.giants:
		var apart := here - giant.body.position
		if giant.standing() and apart.length() < 2.5:
			steering += apart.normalized() * 6.0
	for machine in arena.machines:
		var apart := here - machine.body.position
		if machine.standing() and apart.length() < 4.0:
			steering += apart.normalized() * 8.0
	var glow := arena.fireflies.nearest(here, 5.0)
	if glow.is_finite():
		steering += (glow - here).normalized() * 2.0
	var middle := arena.size / 2.0 - here
	steering += middle * middle.length() / 40.0
	steering += middle.orthogonal().normalized() * 1.5
	return steering.limit_length(1.0)
