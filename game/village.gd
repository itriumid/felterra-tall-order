class_name Village
extends RefCounted
## The cats' village at the forest's edge, and what the runs have brought home to it: the cats
## rescued, by name and coat, and the salvage. Kept in the player's data folder beside the
## settings and the best run.

const PATH := "user://village.cfg"

var cats: Array[Dictionary] = []
var salvage := 0


## What a run brought home: its rescued cats join, its salvage goes on the pile.
func bring_home(arena: Arena) -> void:
	cats.append_array(arena.rescued)
	salvage += arena.salvage


## Back to the start: nobody rescued, nothing on the pile.
func clear() -> void:
	cats.clear()
	salvage = 0


func save(path := PATH) -> bool:
	var file := ConfigFile.new()
	file.set_value("village", "cats", cats)
	file.set_value("village", "salvage", salvage)
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
