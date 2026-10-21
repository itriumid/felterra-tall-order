class_name Village
extends RefCounted
## The cats' village at the forest's edge, and what the runs have brought home to it: the cats
## rescued, by name and coat, and the salvage. Kept in the player's data folder beside the
## settings and the best run.

const PATH := "user://village.cfg"

var cats: Array[Dictionary] = []
var salvage := 0
## Whether the story's opening has been told: it's told once, on the first walk into the village.
var intro_seen := false
## The buildings brought back from ruin, by name.
var restored: Array[String] = []


## What a run brought home: its rescued cats join, its salvage goes on the pile.
func bring_home(arena: Arena) -> void:
	cats.append_array(arena.rescued)
	salvage += arena.salvage


## Back to the start: nobody rescued, nothing on the pile.
func clear() -> void:
	cats.clear()
	salvage = 0
	intro_seen = false
	restored.clear()


func save(path := PATH) -> bool:
	var file := ConfigFile.new()
	file.set_value("village", "cats", cats)
	file.set_value("village", "salvage", salvage)
	file.set_value("village", "intro_seen", intro_seen)
	file.set_value("village", "restored", restored)
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
	var saved_salvage: Variant = file.get_value("village", "salvage", 0)
	if saved_salvage is int:
		salvage = maxi(saved_salvage, 0)
	intro_seen = file.get_value("village", "intro_seen", false) == true
	var saved_restored: Variant = file.get_value("village", "restored", [])
	if saved_restored is Array:
		restored.clear()
		for name: Variant in saved_restored:
			if name is String and name in VillageMap.building_names():
				restored.append(name)
