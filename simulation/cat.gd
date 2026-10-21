class_name Cat
extends RefCounted
## A player's cat: moves freely, dodges, and fires at the nearest enemy on its own. Over a run her
## dodge takes up to three mutations, each changing what it does, not just its numbers.

const SPEED := 2.6
const RADIUS := 0.15
const TALL := 0.45
const MOST_HEALTH := 10.0
## The dodge: a short roll at this speed, hits don't land for part of it, and it takes a charge,
## which comes back over DODGE_COOLDOWN.
const DODGE_SPEED := 6.5
const DODGE_TIME := 0.22
const DODGE_SAFE_TIME := 0.28
const DODGE_COOLDOWN := 0.9
## Dodge mutations: no more than this many in a run.
const MOST_MUTATIONS := 3
## Rolling slash: what a cut does at a roll's full speed, a common card's worth.
const SLASH_DAMAGE := 3.0
## Pounce: as the roll ends, a leap onto the nearest enemy this close, taking this long in the
## air, and what landing does to what's under her.
const POUNCE_REACH := 3.0
const POUNCE_TIME := 0.4
const POUNCE_DAMAGE := 4.0
const POUNCE_RADIUS := 0.4
## Ankle cutter: rolling between a giant's legs cuts this share of his health.
const ANKLE_SHARE := 0.12
## Land on your feet: the free roll after a knock is safe for this long, and longer for more.
const RECOVER_SAFE_TIME := 0.25
const RECOVER_SAFE_GROWTH := 0.1
## More charges: a card's rarity past common makes charges come back this much faster.
const RECHARGE_GROWTH := 0.25
## Long leap: thrown up this fast, so it clears a rat and the chainsaw's sweep at the top; along
## the ground, a share of the roll's speed that grows with each card.
const LEAP_LIFT := 2.9
const LEAP_SPEED := 0.5
const LEAP_GROWTH := 0.15
## Riposte: a hit dodged as it lands strikes back at everything this close.
const RIPOSTE_REACH := 0.9
const RIPOSTE_DAMAGE := 4.0
## A knock off its feet takes this long to recover from.
const STAGGER_TIME := 0.25
## Where the gun is held, above the ground.
const GUN_HEIGHT := 0.2

var body := Body.new()
## Her coat: orange, gray, black or cream. The view draws her fur in it.
var coat := "orange"
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
## The chance a hit lands twice as hard, and how much harder her hits shove.
var critical := 0.0
var knockback_bonus := 0.0
## Offers from level-ups, held until played, oldest first; each is a list of choices.
var offers: Array = []
var rerolls := 2
## Choices banished for the rest of the run, by id.
var banished := {}
## Cards she can't be offered yet, by id: what the village's smith hasn't forged. Empty, anything
## can turn up.
var locked: Array[String] = []
## Where the player is steering, as a direction no longer than 1.
var steering := Vector2.ZERO
## The way she faces and the way her gun points, as unit vectors.
var facing := Vector2.RIGHT
var aim := Vector2.RIGHT
## A cat has two paws: two one-handed weapons, or one that takes both. She starts with one, a
## knife or a handgun, and nothing else: armor and accessories are upgrades.
const PAWS := 2
var weapons: Array[Weapon] = [Weapon.handgun()]
## What she carries on her back, by slot ("drone", "set_down"): one of each at most.
var supports := {}
## How her weapons pick a target: "nearest", "toughest" (the most health left) or "crowd" (the
## thickest cluster).
var aim_mode := "nearest"
## Visible gear, by slot (head, body, neck, eyes, paws, feet, waist), and each piece's level. The
## view draws whatever is named here.
var gear := {}
var gear_levels := {}
var dodging_for := 0.0
var safe_for := 0.0
## Dodges ready, as a stock that refills: one is enough to roll, and More charges holds more.
var dodge_charges := 1.0
var staggered_for := 0.0
## Hits that have landed on her, and dodges, counted, so the view and the sound know when one
## does.
var hits_taken := 0
var dodges := 0
## Her dodge mutations, by id, each as its strength: the amounts of every card taken for it added
## up, so a card for one she has strengthens it without taking another. And how many cards each.
var mutations := {}
var mutation_cards := {}
## Mid-pounce: in the air on her way down onto something.
var pouncing := false
var _dodge_direction := Vector2.RIGHT
var _dodge_speed := DODGE_SPEED
## What this roll has cut already, so it cuts each only once, and whether it has struck back.
var _rolled_through := {}
var _riposted := false
var _riposte_due := false
## A knock to roll out of, once she's down, and whether this roll is a leap.
var _knocked := false
var _leaping := false


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


## Rolls the way she's steering, or the way she faces if she isn't. Returns false if no charge is
## ready.
func dodge() -> bool:
	if dodge_charges < 1.0 or not alive() or body.airborne():
		return false
	dodge_charges -= 1.0
	_roll(steering.normalized() if steering.length_squared() > 0.01 else facing, DODGE_SAFE_TIME)
	return true


func _roll(direction: Vector2, safe_time: float) -> void:
	_dodge_direction = direction
	dodging_for = DODGE_TIME
	_dodge_speed = DODGE_SPEED
	safe_for = maxf(safe_for, safe_time)
	staggered_for = 0.0
	_rolled_through.clear()
	_riposted = false
	dodges += 1
	_leaping = has("long_leap")
	if _leaping:
		# A real jump: as long in the air as the throw makes it, and the roll lasts until she lands.
		body.push(Vector2.ZERO, LEAP_LIFT)
		dodging_for = 2.0 * LEAP_LIFT / Body.GRAVITY
		_dodge_speed = DODGE_SPEED * (LEAP_SPEED + LEAP_GROWTH * strength("long_leap"))


func has(mutation: String) -> bool:
	return mutations.has(mutation)


## How strong a mutation she has is: 1 for a common card's worth, 0 if she hasn't it.
func strength(mutation: String) -> float:
	return mutations.get(mutation, 0.0)


## The most charges she can hold.
func most_charges() -> int:
	return 1 + mutation_cards.get("more_charges", 0)


## How long a spent charge takes to come back.
func recharge_time() -> float:
	var past_common: float = strength("more_charges") - mutation_cards.get("more_charges", 0)
	return DODGE_COOLDOWN / (1.0 + RECHARGE_GROWTH * past_common)


## Damage from her dodge, at a common card's worth: what her gear adds to her weapons adds to it.
func dodge_damage(base: float, mutation: String) -> float:
	return base * strength(mutation) * (1.0 + damage_bonus)


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
		"critical": critical += amount
		"knockback": knockback_bonus += amount


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
	if not alive():
		return false
	if safe_for > 0.0:
		# Dodged just as it landed: she strikes back, once a roll.
		if has("riposte") and not _riposted:
			_riposte_due = true
		return false
	# Armor takes a flat amount off each hit, but never all of it.
	health = maxf(health - maxf(damage - armor, damage * 0.2), 0.0)
	hits_taken += 1
	# Knocked off her feet only from her feet: a cat already in the air isn't thrown higher.
	if not body.airborne():
		body.push(knock, 0.8)
		_knocked = has("land_on_feet")
	staggered_for = STAGGER_TIME
	return true


func step(delta: float, arena: Arena) -> void:
	var was_dodging := dodging_for > 0.0
	dodging_for = maxf(dodging_for - delta, 0.0)
	# A leap is a roll until she's down.
	if _leaping and body.airborne():
		dodging_for = maxf(dodging_for, delta)
	safe_for = maxf(safe_for - delta, 0.0)
	dodge_charges = minf(dodge_charges + delta / recharge_time(), most_charges())
	staggered_for = maxf(staggered_for - delta, 0.0)
	if not alive():
		body.slide(delta)
		body.step(delta)
		return
	_mutate(arena, was_dodging)
	if dodging_for > 0.0:
		body.velocity = _dodge_direction * _dodge_speed
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
	for slot: String in supports:
		(supports[slot] as Support).step(delta, self, arena)


## What her mutations do this step: cuts and strikes from the roll, the pounce at its end, the
## roll out of a knock.
func _mutate(arena: Arena, was_dodging: bool) -> void:
	if _riposte_due:
		_riposte_due = false
		_riposted = true
		arena.riposte(self, dodge_damage(RIPOSTE_DAMAGE, "riposte"))
	if dodging_for > 0.0:
		if has("rolling_slash"):
			var at_speed := _dodge_speed / DODGE_SPEED
			for creature in arena.rolled_into(self):
				if not _rolled_through.has(creature):
					_rolled_through[creature] = true
					arena.strike(creature, dodge_damage(SLASH_DAMAGE, "rolling_slash") * at_speed, _dodge_direction, 1.2, 0.6, "slash", self)
		if has("ankle_cutter"):
			for giant in arena.legs_rolled_between(self):
				if not _rolled_through.has(giant):
					_rolled_through[giant] = true
					arena.strike(giant, giant.most_health * ANKLE_SHARE * strength("ankle_cutter") * (1.0 + damage_bonus), _dodge_direction, 0.0, 0.0, "ankles", self)
	if pouncing and body.height <= 0.0:
		pouncing = false
		body.velocity = Vector2.ZERO
		arena.land_pounce(self, dodge_damage(POUNCE_DAMAGE, "pounce"))
	elif dodging_for <= 0.0 and was_dodging and has("pounce") and not body.airborne():
		var target: Object = arena.target_for(body.position, POUNCE_REACH, aim_mode)
		if target != null:
			# A throw that comes down on it: up for half the time, down for the other half, to where
			# it will be by then, the way a cat leads what she jumps at.
			var toward: Vector2 = target.body.position + target.body.velocity * POUNCE_TIME - body.position
			body.velocity = toward / POUNCE_TIME
			body.vertical_speed = Body.GRAVITY * POUNCE_TIME * 0.5
			facing = toward.normalized() if toward.length_squared() > 0.0001 else facing
			pouncing = true
			arena.events.append({"position": body.position, "height": 0.0, "direction": facing, "killed": false, "by": "leap", "giant": false, "kind": "cat"})
	if _knocked and not body.airborne():
		# Down from the knock, she rolls on the way it threw her, for free.
		_knocked = false
		var thrown := body.velocity.normalized() if body.velocity.length_squared() > 0.01 else -facing
		_roll(thrown, RECOVER_SAFE_TIME + RECOVER_SAFE_GROWTH * strength("land_on_feet"))
