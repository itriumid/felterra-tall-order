extends TestCase
## Restoring the village: a ruin takes salvage and cats to help, and opens what it holds; the
## smith forges gear and support into the cards a run can offer, and a forged piece can be worn
## from a run's start; housed cats weave cloth; the weaver sells looks for it.


func _village(cats: int, salvage: int) -> Village:
	var village := Village.new()
	for index in cats:
		village.cats.append({"name": Cage.NAMES[index % Cage.NAMES.size()], "coat": "gray"})
	village.salvage = salvage
	return village


func test_a_ruin_needs_salvage_and_cats_to_help() -> void:
	var village := _village(0, 100)
	check(not village.restore("smithy") and village.cant_restore("smithy").contains("cat"), "the smithy was restored with nobody to help")
	village = _village(5, 3)
	check(not village.restore("smithy") and village.cant_restore("smithy").contains("salvage"), "the smithy was restored without the salvage")
	village = _village(1, 20)
	check(village.restore("smithy"), "the smithy wasn't restored with all it needs")
	check(village.salvage == 20 - Village.RESTORE.smithy.salvage, "restoring left %d salvage" % village.salvage)
	check(village.cats.size() == 1, "the cats who helped didn't stay")
	check(not village.restore("smithy"), "the smithy was restored twice")


func test_the_smith_forges_into_the_cards() -> void:
	var village := _village(1, 100)
	check(not village.forge("gear:vest"), "a vest was forged with the smithy in ruins")
	village.restore("smithy")
	check(village.forge("gear:vest") and "gear:vest" in village.pool(), "the vest didn't go into the cards")
	check(not village.forge("gear:vest"), "the vest was forged twice")
	check(not village.forge("gear:caping"), "something always in the cards was forged")


func test_what_isnt_forged_is_never_offered() -> void:
	var cat := Cat.new()
	for id: String in Village.FORGE:
		cat.locked.append(id)
	for id in Upgrades.available(cat):
		check(not id in Village.FORGE, "%s was offered before it was forged" % id)
	check("gear:caping" in Upgrades.available(cat), "the caping, always in the cards, wasn't offered")


func test_only_forged_gear_is_worn_from_the_start() -> void:
	var village := _village(1, 100)
	village.restore("smithy")
	check(not village.wear_from_start("gear:vest"), "an unforged vest was worn from the start")
	village.forge("gear:vest")
	check(village.wear_from_start("gear:vest") and village.starting_piece == "gear:vest", "a forged vest couldn't be worn from the start")
	village.forge("support:mines")
	check(not village.wear_from_start("support:mines"), "mines were worn like gear")


func test_housed_cats_weave_cloth() -> void:
	var village := _village(5, 100)
	var arena := Arena.new()
	village.bring_home(arena)
	check(village.cloth == 0, "cats with no roof wove %d cloth" % village.cloth)
	village.restore("hut_0")
	village.restore("hut_1")
	village.bring_home(arena)
	check(village.cloth == 2 * Village.CATS_PER_HUT, "two huts' cats wove %d cloth" % village.cloth)


func test_the_weaver_sells_looks_for_cloth() -> void:
	var village := _village(1, 100)
	village.cloth = 20
	check(not village.buy_look("coat:gray"), "a look was bought with the weaver's hut in ruins")
	village.restore("hut_0")
	check(village.buy_look("coat:gray") and village.wear_look("coat:gray") and village.coat == "gray", "the gray coat couldn't be bought and worn")
	check(village.cloth == 20 - Village.LOOKS["coat:gray"].cloth, "the coat left %d cloth" % village.cloth)
	check(not village.wear_look("coat:black"), "a coat she doesn't own was worn")


func test_everything_comes_back_and_a_reset_clears_it() -> void:
	var village := _village(2, 100)
	village.cloth = 30
	village.restore("smithy")
	village.restore("hut_0")
	village.forge("gear:gloves")
	village.wear_from_start("gear:gloves")
	village.buy_look("banners:lagoon")
	village.wear_look("banners:lagoon")
	var path := "user://test_restoration.cfg"
	village.save(path)
	var loaded := Village.new()
	loaded.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(loaded.restored == ["smithy", "hut_0"] and loaded.forged == ["gear:gloves"], "came back with %s restored, %s forged" % [loaded.restored, loaded.forged])
	check(loaded.starting_piece == "gear:gloves" and loaded.banners == "lagoon" and loaded.cloth == village.cloth, "the starting piece, banners or cloth didn't come back")
	loaded.clear()
	check(loaded.restored.is_empty() and loaded.forged.is_empty() and loaded.starting_piece.is_empty() and loaded.cloth == 0 and loaded.banners == "festival", "a reset left something behind")
