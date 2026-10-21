extends TestCase
## The placeholder soundtrack: every layer loops, all of the same length so they stay in step, none
## silent or clipping; and the layers follow the run.


func test_every_layer_loops_in_step_and_is_heard() -> void:
	var layers := MusicKit.make_all()
	check(layers.size() == MusicKit.LAYERS.size(), "%d layers made" % layers.size())
	for layer: String in layers:
		var wav: AudioStreamWAV = layers[layer]
		check(wav.loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s doesn't loop" % layer)
		check(wav.data.size() / 2 == MusicKit.loop_samples(), "%s is out of step with the rest" % layer)
		var loudest := 0
		for index in range(0, wav.data.size(), 8):
			loudest = maxi(loudest, absi(wav.data.decode_s16(index)))
		check(loudest > 2000, "%s is all but silent" % layer)
		check(loudest < 32000, "%s clips" % layer)


func test_the_village_has_its_own_layers_in_step_and_heard() -> void:
	var layers := MusicKit.make_village()
	check(layers.size() == MusicKit.VILLAGE_LAYERS.size(), "%d village layers made" % layers.size())
	for layer: String in layers:
		var wav: AudioStreamWAV = layers[layer]
		check(wav.loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s doesn't loop" % layer)
		check(wav.data.size() / 2 == MusicKit.loop_samples(MusicKit.VILLAGE_TEMPO), "%s is out of step with the rest" % layer)
		var loudest := 0
		for index in range(0, wav.data.size(), 8):
			loudest = maxi(loudest, absi(wav.data.decode_s16(index)))
		check(loudest > 2000 and loudest < 32000, "%s peaks at %d" % [layer, loudest])


func test_the_village_plays_its_own_music_and_the_run_its_own() -> void:
	var home := MusicDirector.targets(40, true, false, true)
	var run := MusicDirector.targets(40, true, false)
	for layer in MusicKit.LAYERS:
		check(home[layer] == 0.0, "%s played in the village" % layer)
	for layer in MusicKit.VILLAGE_LAYERS:
		check(home[layer] == 1.0 and run[layer] == 0.0, "%s didn't keep to the village" % layer)


func test_the_rock_layer_comes_in_with_a_giant() -> void:
	check(MusicDirector.targets(0, true, false).rock == 1.0, "a giant brought no rock")
	check(MusicDirector.targets(0, false, false).rock == 0.0, "rock played with no giant")


func test_the_music_builds_with_the_horde() -> void:
	var quiet := MusicDirector.targets(0, false, false)
	var crowd := MusicDirector.targets(40, false, false)
	check(quiet.chords == 0.0 and quiet.lead == 0.0, "an empty clearing had the full band")
	check(crowd.chords > 0.9 and crowd.lead > 0.9, "a crush didn't bring the band in")
	check(quiet.drums == 1.0 and quiet.gamelan > 0.0, "the drums or the gamelan dropped out")


func test_the_pause_menu_softens_the_music() -> void:
	var playing := MusicDirector.targets(40, true, false)
	var paused := MusicDirector.targets(40, true, true)
	for layer: String in playing:
		check(paused[layer] < playing[layer] or playing[layer] == 0.0, "%s didn't soften in the pause menu" % layer)
