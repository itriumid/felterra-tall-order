class_name Upgrades
extends RefCounted
## What a level-up card can offer, and what each does. A card offers three choices, each a kind
## of upgrade at a rarity; rarity changes only how much it gives, never what it does.

enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

const RARITY_NAMES: Array[String] = ["Common", "Uncommon", "Rare", "Legendary"]
## How much each tier gives, against a common one.
const AMOUNTS: Array[float] = [1.0, 1.6, 2.4, 3.5]
## How often each tier turns up, before luck.
const WEIGHTS: Array[float] = [60.0, 28.0, 10.0, 2.0]
const CHOICES := 3
const TOP_LEVEL := 5

## Stats come from what she wears, never on their own: each piece of gear gives some, and more
## with each level. What each stat is called and what it does, in one line.
const STATS := {
	"health": {"name": "Health", "explain": "How much she can take before she's down", "format": "+%d health"},
	"armor": {"name": "Armor", "explain": "Each hit takes this much less", "format": "+%.1f armor"},
	"regeneration": {"name": "Regeneration", "explain": "Health that comes back on its own, every second", "format": "+%.2f regeneration"},
	"adrenaline": {"name": "Adrenaline", "explain": "A share of the damage she deals comes back to her as health", "format": "+%d%% adrenaline"},
	"damage": {"name": "Damage", "explain": "Every weapon she holds hits harder", "format": "+%d%% damage"},
	"attack_speed": {"name": "Attack speed", "explain": "Every weapon fires and swings sooner", "format": "+%d%% attack speed"},
	"reach": {"name": "Reach", "explain": "Guns reach further, blades reach longer", "format": "+%d%% reach"},
	"speed": {"name": "Speed", "explain": "She runs faster", "format": "+%d%% speed"},
	"luck": {"name": "Luck", "explain": "Rarer cards turn up more often", "format": "+%.1f luck"},
}
## Stats that most players won't know: a card marks them as worth reading in full.
const UNFAMILIAR: Array[String] = ["adrenaline", "regeneration", "luck"]
## Gear, by id: the slot it's worn in, and what a common level of it gives.
const GEAR := {
	"vest": {"name": "Vest", "slot": "body", "stats": {"armor": 0.4, "health": 2.0}},
	"hard_hat": {"name": "Hard hat", "slot": "head", "stats": {"armor": 0.3, "health": 2.0}},
	"caping": {"name": "Caping", "slot": "head", "stats": {"regeneration": 0.05, "luck": 0.3}},
	"bell_collar": {"name": "Bell collar", "slot": "neck", "stats": {"luck": 0.6}},
	"scarf": {"name": "Red scarf", "slot": "neck", "stats": {"speed": 0.06}},
	"goggles": {"name": "Goggles", "slot": "eyes", "stats": {"reach": 0.08}},
	"gloves": {"name": "Gloves", "slot": "paws", "stats": {"damage": 0.1, "attack_speed": 0.05}},
	"boots": {"name": "Boots", "slot": "feet", "stats": {"speed": 0.05, "armor": 0.1}},
	"jamu_flask": {"name": "Jamu flask", "slot": "waist", "stats": {"adrenaline": 0.03}},
}
const SLOTS: Array[String] = ["head", "body", "neck", "eyes", "paws", "feet", "waist"]
## Weapons a card can hand her, if she has paws free for them.
const WEAPONS: Array[String] = ["knife", "handgun", "submachine_gun"]
const WEAPON_NAMES := {"knife": "Knife", "handgun": "Handgun", "submachine_gun": "Submachine gun"}
## What a level gives a weapon, before rarity.
const LEVEL_DAMAGE := 0.15
const LEVEL_TEMPO := 0.08


## A rarity, rolled. Luck moves the odds toward the rarer tiers.
static func roll_rarity(random: RandomNumberGenerator, luck: float) -> int:
	var weights: Array[float] = []
	var total := 0.0
	for tier in WEIGHTS.size():
		var weight: float = WEIGHTS[tier] * (1.0 + luck * tier * 0.5)
		weights.append(weight)
		total += weight
	var roll := random.randf() * total
	for tier in weights.size():
		roll -= weights[tier]
		if roll <= 0.0:
			return tier
	return Rarity.COMMON


## Everything that could be offered to a cat right now, by id: gear for a free slot, a level for
## gear or a weapon she has, or a weapon for a free paw.
static func available(cat: Cat) -> Array[String]:
	var ids: Array[String] = []
	for id: String in GEAR:
		var slot: String = GEAR[id].slot
		if cat.gear.get(slot, "") == id:
			if cat.gear_levels.get(id, 1) < TOP_LEVEL:
				ids.append("gear_level:" + id)
		elif cat.gear.get(slot, "") == "":
			ids.append("gear:" + id)
	var paws_used := 0
	for weapon in cat.weapons:
		paws_used += weapon.hands
		if weapon.level < TOP_LEVEL:
			ids.append("level:" + weapon.name)
	for weapon_name in WEAPONS:
		var held := cat.weapons.any(func(weapon: Weapon) -> bool: return weapon.name == weapon_name)
		if not held and paws_used + Weapon.named(weapon_name).hands <= Cat.PAWS:
			ids.append("weapon:" + weapon_name)
	return ids.filter(func(id: String) -> bool: return not cat.banished.has(id))


## A fresh offer of three different choices, as [{id, rarity}].
static func offer(cat: Cat, random: RandomNumberGenerator, leaving_out: Array[String] = []) -> Array[Dictionary]:
	var pool := available(cat).filter(func(id: String) -> bool: return not id in leaving_out)
	var choices: Array[Dictionary] = []
	while choices.size() < CHOICES and not pool.is_empty():
		var id: String = pool.pop_at(random.randi_range(0, pool.size() - 1))
		choices.append({"id": id, "rarity": roll_rarity(random, cat.luck)})
	return choices


static func apply(cat: Cat, choice: Dictionary) -> void:
	var id: String = choice.id
	var amount: float = AMOUNTS[choice.rarity]
	if id.begins_with("gear:") or id.begins_with("gear_level:"):
		var gear_id := id.trim_prefix("gear:").trim_prefix("gear_level:")
		var gear: Dictionary = GEAR[gear_id]
		if id.begins_with("gear:"):
			cat.gear[gear.slot] = gear_id
			cat.gear_levels[gear_id] = 1
		else:
			cat.gear_levels[gear_id] = cat.gear_levels.get(gear_id, 1) + 1
		for stat: String in gear.stats:
			cat.raise(stat, gear.stats[stat] * amount)
	elif id.begins_with("level:"):
		for weapon in cat.weapons:
			if weapon.name == id.trim_prefix("level:"):
				weapon.level += 1
				weapon.power += LEVEL_DAMAGE * amount
				weapon.tempo += LEVEL_TEMPO * amount
	elif id.begins_with("weapon:"):
		var weapon := Weapon.named(id.trim_prefix("weapon:"))
		# A rarer find comes better made: a level up for each tier above common.
		for tier in choice.rarity:
			weapon.level += 1
			weapon.power += LEVEL_DAMAGE
			weapon.tempo += LEVEL_TEMPO
		cat.weapons.append(weapon)


## A choice as a card shows it: {name, kind, lines (what it gives), explain (what those mean),
## unfamiliar (whether any of it is worth reading in full), item (the gear or weapon it is)}.
static func describe(choice: Dictionary) -> Dictionary:
	var id: String = choice.id
	var amount: float = AMOUNTS[choice.rarity]
	var card := {"lines": [], "explain": [], "unfamiliar": false, "item": "", "kind": ""}
	if id.begins_with("gear:") or id.begins_with("gear_level:"):
		var gear_id := id.trim_prefix("gear:").trim_prefix("gear_level:")
		var gear: Dictionary = GEAR[gear_id]
		card.item = gear_id
		card.kind = "gear"
		card.name = gear.name if id.begins_with("gear:") else gear.name + " up"
		for stat: String in gear.stats:
			card.lines.append(_amount_text(STATS[stat].format, gear.stats[stat] * amount))
			card.explain.append("%s: %s" % [STATS[stat].name, STATS[stat].explain])
			card.unfamiliar = card.unfamiliar or stat in UNFAMILIAR
	elif id.begins_with("level:"):
		card.item = id.trim_prefix("level:")
		card.kind = "weapon"
		card.name = WEAPON_NAMES[card.item] + " up"
		card.lines = ["+%d%% damage" % roundi(LEVEL_DAMAGE * amount * 100.0), "+%d%% attack speed" % roundi(LEVEL_TEMPO * amount * 100.0)]
		card.explain = ["Weapon levels: each raises its damage and attack speed, up to level %d" % TOP_LEVEL]
	else:
		card.item = id.trim_prefix("weapon:")
		card.kind = "weapon"
		card.name = WEAPON_NAMES[card.item]
		card.lines = ["A new weapon", "Level %d" % (1 + choice.rarity)]
		card.explain = ["Paws: a weapon takes a free one, and she has two"]
	return card


static func _amount_text(text: String, value: float) -> String:
	# Shares read as percentages; the rest as they are.
	if text.contains("%d%%"):
		return text % roundi(value * 100.0)
	if text.contains("%d"):
		return text % roundi(value)
	return text % value
