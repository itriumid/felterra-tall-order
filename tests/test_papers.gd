extends TestCase
## Writing is the one bridge between the cats and the giants. Each area the company holds has a
## paper lying in it; brought home, Granny Whiskers reads it and keeps a word; and with five words
## the cats can write back, which is how the airstrip ends.


func _area_with_cat(area_id: String, papers_home: Array[String] = []) -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	arena.begin_area(area_id, false, papers_home)
	arena.add_cat(arena.area.start)
	return arena


func test_every_area_the_company_holds_has_a_paper_and_the_five_words_make_the_sign() -> void:
	var words: Array[String] = []
	for id in Areas.WRITING:
		var area := Areas.named(id)
		check(area.has("paper"), "%s gives a word but has no paper" % id)
		words.append(area.paper.word)
	var sign_words := Areas.SIGN.replace(".", "").split(" ")
	for word in sign_words:
		check(word in words, 'the sign says "%s", which no paper gives' % word)
	check(sign_words.size() == words.size(), "the sign has %d words for %d papers" % [sign_words.size(), words.size()])
	for id in Areas.WRITING:
		check(Areas.named(id).paper.reads.contains(Areas.named(id).paper.word), "%s's paper never says the word it gives" % id)
	check(not Areas.named("edge").has("paper") and not Areas.named("siege").has("paper"), "the rats and the spirits don't write to be read")


func test_a_paper_lies_clear_of_what_stands_until_he_walks_over_it() -> void:
	for id in Areas.ids():
		if not Areas.named(id).has("paper"):
			continue
		var arena := _area_with_cat(id)
		check(not arena.paper.is_empty(), "%s's paper isn't lying there" % id)
		check(not arena.solid_at(arena.paper.position, 0.2), "%s's paper lies inside something" % id)
		arena.step()
		check(not arena.paper_found, "he had %s's paper without going to it" % id)
		arena.cats[0].body.position = arena.paper.position + Vector2(0.2, 0.0)
		arena.step()
		check(arena.paper_found, "he walked over %s's paper and left it" % id)
		check(arena.calls.any(func(line: Dictionary) -> bool: return line.text == arena.area.paper.found), "he said nothing on finding it")
		check(Village.earnings_of(arena).paper == id, "%s's paper isn't among what the run brings home" % id)


func test_a_paper_brought_home_is_not_lying_there_again() -> void:
	var arena := _area_with_cat("deep", ["deep"])
	check(arena.paper.is_empty(), "the Handler's list was back where it had been")
	check(Village.earnings_of(arena).paper == "", "a run with no paper brought one home")


func test_granny_reads_them_once_she_is_home() -> void:
	var village := Village.new()
	village.take_earnings({"paper": "deep"})
	village.read_papers()
	check(village.papers == ["deep"] and village.papers_read.is_empty(), "the list was read with nobody home who can read")
	check(not village.has_tidings("hut_0"), "there's news at a ruin")
	village.liberate("edge")
	village.liberate("deep")
	village.catch_up()
	village.read_papers()
	check(village.papers_read == ["deep"], "home, she didn't read the list")
	var heard := village.hear("hut_0").filter(func(item: Dictionary) -> bool: return item.title == "The Handler's list")
	check(heard.size() == 1 and (heard[0].text as String).contains("CATS"), "what the list said isn't waiting at her door")
	village.take_earnings({"paper": "deep"})
	village.read_papers()
	check(village.papers == ["deep"] and not village.has_tidings("hut_0"), "the same paper was brought home and read twice")


func test_with_five_words_the_cats_can_write() -> void:
	var village := Village.new()
	village.liberate("edge")
	village.liberate("deep")
	village.catch_up()
	for id in Areas.WRITING.slice(0, 4):
		village.take_earnings({"paper": id})
	village.read_papers()
	check(not village.can_write(), "four words were enough")
	check(Areas.after_lines("airstrip", village.can_write()) == Areas.named("airstrip").after, "the airstrip ended with a sign nobody could write")
	village.take_earnings({"paper": Areas.WRITING[4]})
	village.read_papers()
	check(village.can_write(), "five words weren't enough")
	var heard := village.hear("hut_0")
	check(heard.any(func(item: Dictionary) -> bool: return item.title == "Five words"), "she had the five words and nothing to say")
	check(Village.FIVE_WORDS in village.told, "hearing the five words wasn't kept")
	var ending := Areas.after_lines("airstrip", village.can_write())
	check(ending.any(func(line: Variant) -> bool: return line is String and line.contains(Areas.SIGN)), "with the words, the airstrip's ending doesn't show the sign")
	check(Areas.send_off_lines("airstrip", true).size() == Areas.send_off_lines("airstrip").size() + 1, "nobody says the sign is being painted")


func test_the_papers_are_kept() -> void:
	var path := "user://test_papers_village.cfg"
	var village := Village.new()
	village.liberate("edge")
	village.liberate("deep")
	village.catch_up()
	village.take_earnings({"paper": "deep"})
	village.take_earnings({"paper": "sawpits"})
	village.read_papers()
	village.told.append(Village.SIGN_LATER)
	check(village.save(path), "the village couldn't be kept")
	var kept := Village.new()
	kept.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(kept.papers == ["deep", "sawpits"] and kept.papers_read == ["deep", "sawpits"], "the papers weren't kept: %s, %s" % [kept.papers, kept.papers_read])
	check(Village.SIGN_LATER in kept.told, "that the sign went up wasn't kept")
