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
## Weapons take levels up to WEAPON_TOP, then evolve along their family, or at the last of it
## take mastery; gear takes levels up to GEAR_TOP, then mastery. Two tracks, tuned apart.
const WEAPON_TOP := 10
const GEAR_TOP := 5

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
const WEAPON_NAMES := {
	"knife": "Knife", "keris": "Keris", "kerambit": "Kerambit",
	"handgun": "Handgun", "submachine_gun": "Submachine gun",
}
## Support, by id: what she carries on her back, and the slot it takes there.
const SUPPORT := {
	"gun_drone": {"name": "Gun drone", "lines": ["A drone on her pack", "Flies out and fires"]},
	"meriam_bambu": {"name": "Meriam bambu", "lines": ["A bamboo cannon", "Set down, it lobs stones"]},
	"mines": {"name": "Mines", "lines": ["Pouches of mines", "Dropped as they close"]},
}
## What each support slot is called on a card.
const SUPPORT_SLOT_NAMES := {"drone": "drone", "set_down": "set-down"}
## What a weapon at the top level can become: the families it evolves along. A weapon not listed
## is the last of its family, and takes mastery from there.
const EVOLVES := {"knife": "keris", "keris": "kerambit", "handgun": "submachine_gun"}
## Dodge mutations: each changes what the dodge does. A cat takes up to Cat.MOST_MUTATIONS a run,
## and a card for one she has strengthens it. What each is called, and what it does in one line.
const MUTATIONS := {
	"rolling_slash": {"name": "Rolling slash", "explain": "The roll cuts what it passes through, harder the faster she rolls"},
	"pounce": {"name": "Pounce", "explain": "As the roll ends, she leaps onto the nearest enemy, over the horde"},
	"ankle_cutter": {"name": "Ankle cutter", "explain": "Rolling between a giant's legs cuts a share of his health"},
	"land_on_feet": {"name": "Land on your feet", "explain": "Knocked off her feet, she rolls out of it, for free"},
	"more_charges": {"name": "More charges", "explain": "Dodges she can hold; a rarer card brings them back faster"},
	"long_leap": {"name": "Long leap", "explain": "The roll leaves the ground: over rats, and over a chainsaw's sweep"},
	"riposte": {"name": "Riposte", "explain": "A hit dodged just as it lands, she answers at once"},
}
## Past the top level, mastery: unlimited levels, each worth this share of an ordinary one. It's
## what lets a long run keep growing.
const MASTERY := 0.5
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
			ids.append(("gear_level:" if cat.gear_levels.get(id, 1) < GEAR_TOP else "gear_mastery:") + id)
		elif cat.gear.get(slot, "") == "":
			ids.append("gear:" + id)
	var paws_used := 0
	for weapon in cat.weapons:
		paws_used += weapon.hands
		if weapon.level < WEAPON_TOP:
			ids.append("level:" + weapon.name)
		elif EVOLVES.has(weapon.name):
			ids.append("evolve:" + weapon.name)
		else:
			ids.append("mastery:" + weapon.name)
	for support_name: String in SUPPORT:
		var slot: String = Support.SLOTS[support_name]
		var held: Support = cat.supports.get(slot)
		if held == null:
			ids.append("support:" + support_name)
		elif held.name == support_name:
			ids.append(("support_level:" if held.level < WEAPON_TOP else "support_mastery:") + support_name)
	for mutation: String in MUTATIONS:
		if cat.has(mutation):
			ids.append("mutation_up:" + mutation)
		elif cat.mutations.size() < Cat.MOST_MUTATIONS:
			ids.append("mutation:" + mutation)
	for weapon_name in WEAPONS:
		var family_held := cat.weapons.any(func(weapon: Weapon) -> bool: return _family(weapon.name) == _family(weapon_name))
		if not family_held and paws_used + Weapon.named(weapon_name).hands <= Cat.PAWS:
			ids.append("weapon:" + weapon_name)
	return ids.filter(func(id: String) -> bool: return not cat.banished.has(id) and not id in cat.locked)


## The first weapon of a family: a keris is a knife that grew up.
static func _family(weapon_name: String) -> String:
	for from: String in EVOLVES:
		if EVOLVES[from] == weapon_name:
			return _family(from)
	return weapon_name


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
	if id.begins_with("gear"):
		var gear_id := id.get_slice(":", 1)
		var gear: Dictionary = GEAR[gear_id]
		var share := 1.0
		if id.begins_with("gear:"):
			cat.gear[gear.slot] = gear_id
			cat.gear_levels[gear_id] = 1
		else:
			cat.gear_levels[gear_id] = cat.gear_levels.get(gear_id, 1) + 1
			if id.begins_with("gear_mastery:"):
				share = MASTERY
		for stat: String in gear.stats:
			cat.raise(stat, gear.stats[stat] * amount * share)
	elif id.begins_with("level:") or id.begins_with("mastery:"):
		var share := MASTERY if id.begins_with("mastery:") else 1.0
		for weapon in cat.weapons:
			if weapon.name == id.get_slice(":", 1):
				weapon.level += 1
				weapon.power += LEVEL_DAMAGE * amount * share
				weapon.tempo += LEVEL_TEMPO * amount * share
	elif id.begins_with("evolve:"):
		for index in cat.weapons.size():
			var old: Weapon = cat.weapons[index]
			if old.name != id.get_slice(":", 1):
				continue
			# It keeps everything its levels gave it, and rarity adds a little more.
			var grown := Weapon.named(EVOLVES[old.name])
			grown.power = old.power + LEVEL_DAMAGE * (amount - 1.0)
			grown.tempo = old.tempo + LEVEL_TEMPO * (amount - 1.0)
			cat.weapons[index] = grown
	elif id.begins_with("support:"):
		var support := Support.named(id.trim_prefix("support:"))
		# A rarer find comes better made, as a weapon does.
		for tier in choice.rarity:
			support.level += 1
			support.power += LEVEL_DAMAGE
			support.tempo += LEVEL_TEMPO
		cat.supports[support.slot] = support
	elif id.begins_with("support_level:") or id.begins_with("support_mastery:"):
		var support: Support = cat.supports[Support.SLOTS[id.get_slice(":", 1)]]
		var share := MASTERY if id.begins_with("support_mastery:") else 1.0
		support.level += 1
		support.power += LEVEL_DAMAGE * amount * share
		support.tempo += LEVEL_TEMPO * amount * share
	elif id.begins_with("mutation"):
		var mutation := id.get_slice(":", 1)
		cat.mutations[mutation] = cat.strength(mutation) + amount
		cat.mutation_cards[mutation] = cat.mutation_cards.get(mutation, 0) + 1
		if mutation == "more_charges":
			# The new charge comes ready.
			cat.dodge_charges += 1.0
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
	if id.begins_with("gear"):
		var gear_id := id.get_slice(":", 1)
		var gear: Dictionary = GEAR[gear_id]
		var mastery := id.begins_with("gear_mastery:")
		card.item = gear_id
		card.kind = "gear"
		card.name = gear.name if id.begins_with("gear:") else gear.name + (" mastery" if mastery else " up")
		for stat: String in gear.stats:
			card.lines.append(_amount_text(STATS[stat].format, gear.stats[stat] * amount * (MASTERY if mastery else 1.0)))
			card.explain.append("%s: %s" % [STATS[stat].name, STATS[stat].explain])
			card.unfamiliar = card.unfamiliar or stat in UNFAMILIAR
		if mastery:
			card.explain.append("Mastery: past level %d, there's no limit; each is worth half a level" % GEAR_TOP)
	elif id.begins_with("evolve:"):
		var from := id.get_slice(":", 1)
		card.item = EVOLVES[from]
		card.kind = "weapon"
		card.name = WEAPON_NAMES[card.item]
		card.lines = ["The %s evolves" % WEAPON_NAMES[from].to_lower(), "Keeps all its levels"]
		card.explain = ["Evolving: at level %d a weapon can grow into the next of its family" % WEAPON_TOP]
	elif id.begins_with("level:") or id.begins_with("mastery:"):
		var mastery := id.begins_with("mastery:")
		var share := MASTERY if mastery else 1.0
		card.item = id.get_slice(":", 1)
		card.kind = "weapon"
		card.name = WEAPON_NAMES[card.item] + (" mastery" if mastery else " up")
		card.lines = ["+%d%% damage" % roundi(LEVEL_DAMAGE * amount * share * 100.0), "+%d%% attack speed" % roundi(LEVEL_TEMPO * amount * share * 100.0)]
		if mastery:
			card.explain = ["Mastery: past level %d, there's no limit; each is worth half a level" % WEAPON_TOP]
			return card
		card.explain = ["Weapon levels: each raises its damage and attack speed; at level %d it evolves" % WEAPON_TOP]
	elif id.begins_with("support"):
		var support_name := id.get_slice(":", 1)
		card.item = support_name
		card.kind = "support"
		var slot_name: String = SUPPORT_SLOT_NAMES[Support.SLOTS[support_name]]
		if id.begins_with("support:"):
			card.name = SUPPORT[support_name].name
			card.lines = (SUPPORT[support_name].lines as Array).duplicate()
			card.explain = ["Support: on her back, one drone and one thing set down; this is her %s" % slot_name]
		else:
			var mastery := id.begins_with("support_mastery:")
			var share := MASTERY if mastery else 1.0
			card.name = SUPPORT[support_name].name + (" mastery" if mastery else " up")
			card.lines = ["+%d%% damage" % roundi(LEVEL_DAMAGE * amount * share * 100.0), "+%d%% attack speed" % roundi(LEVEL_TEMPO * amount * share * 100.0)]
			card.explain = ["Support levels: each raises its damage and how often it fires"]
			if mastery:
				card.explain.append("Mastery: past level %d, there's no limit; each is worth half a level" % WEAPON_TOP)
	elif id.begins_with("mutation"):
		var mutation := id.get_slice(":", 1)
		card.item = mutation
		card.kind = "mutation"
		card.name = MUTATIONS[mutation].name + ("" if id.begins_with("mutation:") else " up")
		card.lines = _mutation_lines(mutation, amount, id.begins_with("mutation:"))
		card.explain = ["%s: %s" % [MUTATIONS[mutation].name, MUTATIONS[mutation].explain],
			"Dodge mutations: %d a run; another card for one makes it stronger" % Cat.MOST_MUTATIONS]
		card.unfamiliar = true
	else:
		card.item = id.trim_prefix("weapon:")
		card.kind = "weapon"
		card.name = WEAPON_NAMES[card.item]
		card.lines = ["A new weapon", "Level %d" % (1 + choice.rarity)]
		card.explain = ["Paws: a weapon takes a free one, and she has two"]
	return card


## What a card for a mutation gives, at its rarity's amount, in two short lines: what it does, for
## a new one, or what it adds, for one she has.
static func _mutation_lines(mutation: String, amount: float, fresh: bool) -> Array:
	var leap_time := 2.0 * Cat.LEAP_LIFT / Body.GRAVITY
	match mutation:
		"rolling_slash":
			return ["The roll cuts" if fresh else "Sharper", "%s%.1f damage a cut" % ["" if fresh else "+", Cat.SLASH_DAMAGE * amount]]
		"pounce":
			return ["Ends in a pounce" if fresh else "Harder", "%s%.1f damage landing" % ["" if fresh else "+", Cat.POUNCE_DAMAGE * amount]]
		"ankle_cutter":
			return ["Roll through his legs" if fresh else "Deeper", "%s%d%% of his health" % ["" if fresh else "+", roundi(Cat.ANKLE_SHARE * amount * 100.0)]]
		"land_on_feet":
			if fresh:
				return ["Knocked, she rolls", "Safe for %.2f seconds" % (Cat.RECOVER_SAFE_TIME + Cat.RECOVER_SAFE_GROWTH * amount)]
			return ["Safer", "+%.2f seconds safe" % (Cat.RECOVER_SAFE_GROWTH * amount)]
		"more_charges":
			if amount > 1.0:
				return ["+1 dodge charge", "Recharge %d%% faster" % roundi(Cat.RECHARGE_GROWTH * (amount - 1.0) * 100.0)]
			return ["+1 dodge charge"]
		"long_leap":
			if fresh:
				return ["The roll is a leap", "%.1f meters long" % (Cat.DODGE_SPEED * (Cat.LEAP_SPEED + Cat.LEAP_GROWTH * amount) * leap_time)]
			return ["Further", "+%.1f meters" % (Cat.DODGE_SPEED * Cat.LEAP_GROWTH * amount * leap_time)]
		"riposte":
			return ["Dodge as a hit lands" if fresh else "Sharper", "%s%.1f damage back" % ["" if fresh else "+", Cat.RIPOSTE_DAMAGE * amount]]
	return []


static func _amount_text(text: String, value: float) -> String:
	# Shares read as percentages; the rest as they are.
	if text.contains("%d%%"):
		return text % roundi(value * 100.0)
	if text.contains("%d"):
		return text % roundi(value)
	return text % value
