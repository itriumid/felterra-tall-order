class_name Cat
extends RefCounted
## A player's cat: moves freely, dodges, and fires at the nearest enemy on its own.

const SPEED := 2.6
const RADIUS := 0.15
const TALL := 0.45
const MOST_HEALTH := 10.0
## The dodge: a short roll at this speed, hits don't land for part of it, then a cooldown.
const DODGE_SPEED := 6.5
const DODGE_TIME := 0.22
const DODGE_SAFE_TIME := 0.28
const DODGE_COOLDOWN := 0.9
## A knock off its feet takes this long to recover from.
const STAGGER_TIME := 0.25
## Where the gun is held, above the ground.
const GUN_HEIGHT := 0.2

var body := Body.new()
var health := MOST_HEALTH
var max_health := MOST_HEALTH
## Stats, raised by cards and gear. Bonuses are shares added to one: 0.1 is ten percent more.
var armor := 0.0
var regeneration := 0.0
var adrenaline := 0.0
var damage_bonus := 0.0
var attack_speed_bonus := 0.0
var reach_bonus := 0.0
var speed_bonus := 0.0
var luck := 0.0
## Offers from level-ups, held until played, oldest first; each is a list of choices.
var offers: Array = []
var rerolls := 2
## Choices banished for the rest of the run, by id.
var banished := {}
## Where the player is steering, as a direction no longer than 1.
var steering := Vector2.ZERO
## The way she faces and the way her gun points, as unit vectors.
var facing := Vector2.RIGHT
var aim := Vector2.RIGHT
## A cat has two paws: two one-handed weapons, or one that takes both. She starts with one, a
## knife or a handgun, and nothing else: armor and accessories are upgrades.
const PAWS := 2
var weapons: Array[Weapon] = [Weapon.handgun()]
## How her weapons pick a target: "nearest", "toughest" (the most health left) or "crowd" (the
## thickest cluster).
var aim_mode := "nearest"
## Visible gear, by slot (head, body, neck, eyes, paws, feet, waist), and each piece's level. The
## view draws whatever is named here.
var gear := {}
var gear_levels := {}
var dodging_for := 0.0
var safe_for := 0.0
var dodge_ready_in := 0.0
var staggered_for := 0.0
## Hits that have landed on her, counted, so the view and the sound know when one does.
var hits_taken := 0
var _dodge_direction := Vector2.RIGHT


func _init() -> void:
	body.radius = RADIUS
	body.tall = TALL
	body.restitution = 0.2


## Puts on a set of gear, and takes up the weapons it names, as many as her paws can hold.
func wear(outfit: Dictionary) -> void:
	gear = {}
	for slot: String in outfit:
		if slot != "weapons":
			gear[slot] = outfit[slot]
	weapons.clear()
	var paws_used := 0
	for weapon_name: String in outfit.get("weapons", ["handgun"]):
		var weapon := Weapon.named(weapon_name)
		if paws_used + weapon.hands > PAWS:
			break
		paws_used += weapon.hands
		weapons.append(weapon)


func alive() -> bool:
	return health > 0.0


## Rolls the way she's steering, or the way she faces if she isn't. Returns false if the dodge
## isn't ready.
func dodge() -> bool:
	if dodge_ready_in > 0.0 or not alive() or body.airborne():
		return false
	_dodge_direction = steering.normalized() if steering.length_squared() > 0.01 else facing
	dodging_for = DODGE_TIME
	safe_for = DODGE_SAFE_TIME
	dodge_ready_in = DODGE_COOLDOWN
	return true


## Raises a stat by an amount.
func raise(stat: String, amount: float) -> void:
	match stat:
		"health":
			max_health += amount
			health += amount
		"armor": armor += amount
		"regeneration": regeneration += amount
		"adrenaline": adrenaline += amount
		"damage": damage_bonus += amount
		"attack_speed": attack_speed_bonus += amount
		"reach": reach_bonus += amount
		"speed": speed_bonus += amount
		"luck": luck += amount


func heal(amount: float) -> void:
	if alive() and amount > 0.0 and health < max_health:
		health = minf(health + amount, max_health)


## Plays a choice from the oldest offer held. Returns false if there's no such choice.
func play(index: int) -> bool:
	if offers.is_empty() or index >= (offers[0] as Array).size():
		return false
	var offer: Array = offers.pop_front()
	Upgrades.apply(self, offer[index])
	return true


## Swaps the oldest offer for a fresh one, if a reroll is left.
func reroll(random: RandomNumberGenerator) -> bool:
	if offers.is_empty() or rerolls <= 0:
		return false
	rerolls -= 1
	offers[0] = Upgrades.offer(self, random)
	return true


## Banishes a choice from the oldest offer for the rest of the run, and puts another in its place.
func banish(index: int, random: RandomNumberGenerator) -> bool:
	if offers.is_empty() or index >= (offers[0] as Array).size():
		return false
	var offer: Array = offers[0]
	banished[offer[index].id] = true
	var showing: Array[String] = []
	for choice: Dictionary in offer:
		showing.append(choice.id)
	var replacement := Upgrades.offer(self, random, showing)
	if replacement.is_empty():
		offer.remove_at(index)
	else:
		offer[index] = replacement[0]
	return true


func hurt(damage: float, knock: Vector2) -> bool:
	if safe_for > 0.0 or not alive():
		return false
	# Armor takes a flat amount off each hit, but never all of it.
	health = maxf(health - maxf(damage - armor, damage * 0.2), 0.0)
	hits_taken += 1
	# Knocked off her feet only from her feet: a cat already in the air isn't thrown higher.
	if not body.airborne():
		body.push(knock, 0.8)
	staggered_for = STAGGER_TIME
	return true


func step(delta: float, arena: Arena) -> void:
	dodging_for = maxf(dodging_for - delta, 0.0)
	safe_for = maxf(safe_for - delta, 0.0)
	dodge_ready_in = maxf(dodge_ready_in - delta, 0.0)
	staggered_for = maxf(staggered_for - delta, 0.0)
	if not alive():
		body.slide(delta)
		body.step(delta)
		return
	if dodging_for > 0.0:
		body.velocity = _dodge_direction * DODGE_SPEED
	elif body.airborne() or staggered_for > 0.0:
		body.slide(delta)
	else:
		body.velocity = steering.limit_length(1.0) * SPEED * (1.0 + speed_bonus)
	heal(regeneration * delta)
	if steering.length_squared() > 0.01:
		facing = steering.normalized()
	body.step(delta)
	var longest := 0.0
	for weapon in weapons:
		longest = maxf(longest, weapon.reach_for(self))
	var target := arena.target_for(body.position, longest, aim_mode)
	if target != null:
		aim = (target.body.position - body.position).normalized()
		# Standing still, she turns to face what she's fighting.
		if steering.length_squared() <= 0.01 and dodging_for <= 0.0:
			facing = aim
	for weapon in weapons:
		weapon.step(delta, self, arena)
