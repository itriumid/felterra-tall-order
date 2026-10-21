class_name Village
extends RefCounted
## The cats' village at the forest's edge, and everything that carries over between runs: the
## cats rescued, by name and coat; the salvage and the cloth; the buildings restored from ruin;
## what the smith has forged; and the looks bought. Kept in the player's data folder beside the
## settings and the best run.
##
## Restoring a building takes salvage and rescued cats to help. Each opens what it holds: the
## smithy forges, the longhouse's elder lets a run start with anything forged, and every hut
## houses two cats, who weave cloth while she's away. The first hut is the weaver's, and sells
## looks for cloth. Forging puts gear and support into the cards a run can offer, and a forged
## piece of gear can be worn from a run's start. Unlocks, never stats on their own: runs grow
## wider, not easier.

const PATH := "user://village.cfg"

## What restoring each building takes: salvage, and rescued cats to help (they stay rescued).
const RESTORE := {
	"smithy": {"salvage": 15, "cats": 1},
	"hut_0": {"salvage": 10, "cats": 1}, "hut_1": {"salvage": 12, "cats": 2},
	"hut_2": {"salvage": 15, "cats": 3}, "hut_3": {"salvage": 18, "cats": 4},
	"hut_4": {"salvage": 22, "cats": 5}, "hut_5": {"salvage": 26, "cats": 6},
	"longhouse": {"salvage": 40, "cats": 6},
}
## What each building opens, in a line, for its prompt.
const OPENS := {
	"smithy": "the smith forges new gear",
	"longhouse": "start a run with anything forged",
	"hut_0": "the weaver sells looks for cloth",
}
## Cats a restored hut houses, each weaving a cloth a run.
const CATS_PER_HUT := 2
## What can be forged, by card id, and its salvage. Anything not here is in the cards from the
## start: the knife, the handgun, the caping, the red scarf, the boots, and every dodge mutation.
## What a family grows into needs no forging: a forged rifle can evolve into a sniper rifle.
const FORGE := {
	"gear:vest": 8, "gear:hard_hat": 10, "gear:bell_collar": 6, "gear:goggles": 8,
	"gear:gloves": 10, "gear:jamu_flask": 12, "gear:peci": 8, "gear:batik_shirt": 10,
	"gear:raincoat": 10, "gear:headlamp": 9, "gear:sunglasses": 12, "gear:bandana": 8,
	"gear:wristbands": 10, "gear:rubber_boots": 9, "gear:sandals": 8, "gear:sarong": 10,
	"gear:tool_belt": 11,
	"weapon:machete": 10, "weapon:golok": 12, "weapon:badik": 10, "weapon:rencong": 12,
	"weapon:celurit": 14, "weapon:kujang": 14, "weapon:mandau": 16, "weapon:tombak": 16,
	"weapon:bambu_runcing": 10, "weapon:rattan_staff": 12,
	"weapon:ketapel": 10, "weapon:sumpit": 14, "weapon:panah": 16, "weapon:petasan": 14,
	"weapon:lamp_oil": 15, "weapon:nail_gun": 14, "weapon:flare_gun": 16, "weapon:rifle": 18,
	"weapon:crossbow": 18, "weapon:shotgun": 20, "weapon:grenade_launcher": 24,
	"support:gun_drone": 20, "support:net_drone": 18, "support:layang_layang": 16,
	"support:meriam_bambu": 18, "support:mines": 15, "support:ranjau_bambu": 12, "support:radio": 14,
}
## Looks, by id: what each is and what it costs in cloth. Her coat, and the umbul-umbul's colors.
const LOOKS := {
	"coat:orange": {"name": "Orange coat", "cloth": 0},
	"coat:gray": {"name": "Gray coat", "cloth": 6},
	"coat:black": {"name": "Black coat", "cloth": 8},
	"coat:cream": {"name": "Cream coat", "cloth": 8},
	"banners:festival": {"name": "Festival banners", "cloth": 0},
	"banners:rhodonite": {"name": "Rhodonite banners", "cloth": 10},
	"banners:lagoon": {"name": "Lagoon banners", "cloth": 10},
}

var cats: Array[Dictionary] = []
var salvage := 0
var cloth := 0
## Whether the story's opening has been told: it's told once, on the first walk into the village.
var intro_seen := false
## The buildings brought back from ruin, by name.
var restored: Array[String] = []
## What the smith has forged, by card id, and the piece of gear worn from a run's start ("" none).
var forged: Array[String] = []
var starting_piece := ""
## The looks bought, by id, and the ones worn: her coat, and the banners' colors.
var looks: Array[String] = ["coat:orange", "banners:festival"]
var coat := "orange"
var banners := "festival"


## What a run brought home: its rescued cats join, its salvage goes on the pile, and the cats
## housed in the village weave while she's away.
func bring_home(arena: Arena) -> void:
	cats.append_array(arena.rescued)
	salvage += arena.salvage
	cloth += weavers()


## The cats housed in restored huts, who weave: two to a hut, no more than there are cats.
func weavers() -> int:
	var huts := restored.filter(func(name: String) -> bool: return name.begins_with("hut_")).size()
	return mini(cats.size(), huts * CATS_PER_HUT)


func is_restored(building: String) -> bool:
	return building in restored


## Why a building can't be restored yet ("" if it can): too little salvage, or too few cats.
func cant_restore(building: String) -> String:
	if is_restored(building):
		return "already restored"
	var cost: Dictionary = RESTORE[building]
	if cats.size() < cost.cats:
		return "needs %d %s to help" % [cost.cats, "cat" if cost.cats == 1 else "cats"]
	if salvage < cost.salvage:
		return "needs %d salvage" % cost.salvage
	return ""


## Restores a building, spending its salvage. Returns false if it can't be yet.
func restore(building: String) -> bool:
	if not cant_restore(building).is_empty():
		return false
	salvage -= RESTORE[building].salvage
	restored.append(building)
	return true


## Forges an item into the cards, spending its salvage. The smithy has to be restored first.
func forge(id: String) -> bool:
	if not is_restored("smithy") or id in forged or not FORGE.has(id) or salvage < FORGE[id]:
		return false
	salvage -= FORGE[id]
	forged.append(id)
	return true


## Every card id a run may offer from: what's always there, and what's been forged.
func pool() -> Array[String]:
	var ids: Array[String] = []
	for id: String in FORGE:
		if id in forged:
			ids.append(id)
	return ids


## Wears a forged piece of gear from a run's start, or none ("").
func wear_from_start(id: String) -> bool:
	if not id.is_empty() and (not id.begins_with("gear:") or not id in forged):
		return false
	starting_piece = id
	return true


## Buys a look for cloth, once; the weaver's hut has to be restored first.
func buy_look(id: String) -> bool:
	if id in looks:
		return true
	if not is_restored("hut_0") or not LOOKS.has(id) or cloth < LOOKS[id].cloth:
		return false
	cloth -= LOOKS[id].cloth
	looks.append(id)
	return true


## Wears a look she owns: a coat, or the banners' colors.
func wear_look(id: String) -> bool:
	if not id in looks:
		return false
	if id.begins_with("coat:"):
		coat = id.trim_prefix("coat:")
	else:
		banners = id.trim_prefix("banners:")
	return true


## Back to the start: nobody rescued, nothing on the pile, every building in ruins.
func clear() -> void:
	cats.clear()
	salvage = 0
	cloth = 0
	intro_seen = false
	restored.clear()
	forged.clear()
	starting_piece = ""
	looks.assign(["coat:orange", "banners:festival"])
	coat = "orange"
	banners = "festival"


func save(path := PATH) -> bool:
	var file := ConfigFile.new()
	file.set_value("village", "cats", cats)
	file.set_value("village", "salvage", salvage)
	file.set_value("village", "cloth", cloth)
	file.set_value("village", "intro_seen", intro_seen)
	file.set_value("village", "restored", restored)
	file.set_value("village", "forged", forged)
	file.set_value("village", "starting_piece", starting_piece)
	file.set_value("village", "looks", looks)
	file.set_value("village", "coat", coat)
	file.set_value("village", "banners", banners)
	return file.save(path) == OK


func load_from(path := PATH) -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	var saved_cats: Variant = file.get_value("village", "cats", [])
	if saved_cats is Array:
		cats.clear()
		for each: Variant in saved_cats:
			if each is Dictionary and each.has("name") and each.has("coat"):
				cats.append(each)
	salvage = _count(file, "salvage")
	cloth = _count(file, "cloth")
	intro_seen = file.get_value("village", "intro_seen", false) == true
	_names(file, "restored", restored, VillageMap.building_names())
	_names(file, "forged", forged, FORGE.keys())
	_names(file, "looks", looks, LOOKS.keys())
	for kept: String in ["coat:orange", "banners:festival"]:
		if not kept in looks:
			looks.append(kept)
	var piece: Variant = file.get_value("village", "starting_piece", "")
	starting_piece = piece if piece is String and piece in forged else ""
	var saved_coat: Variant = file.get_value("village", "coat", "orange")
	coat = saved_coat if saved_coat is String and "coat:" + saved_coat in looks else "orange"
	var saved_banners: Variant = file.get_value("village", "banners", "festival")
	banners = saved_banners if saved_banners is String and "banners:" + saved_banners in looks else "festival"


## A count from the file, never below none.
static func _count(file: ConfigFile, key: String) -> int:
	var saved: Variant = file.get_value("village", key, 0)
	return maxi(saved, 0) if saved is int else 0


## A list of names from the file, keeping only the ones there are.
static func _names(file: ConfigFile, key: String, into: Array[String], known: Array) -> void:
	var saved: Variant = file.get_value("village", key, [])
	if not saved is Array:
		return
	into.clear()
	for name: Variant in saved:
		if name is String and name in known and not name in into:
			into.append(name)
