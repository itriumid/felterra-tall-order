extends TestCase
## What he's playing, said to Discord over its local socket: against a pretend Discord listening
## where the real one would, the handshake with the game's application, then the activity, as
## Discord reads it. (Windows's named pipe is the same frames, through a file.)


func test_frames_are_what_discord_reads() -> void:
	var bytes := DiscordPresence.frame(DiscordPresence.HANDSHAKE, {"v": 1, "client_id": "1"})
	var body := '{"client_id":"1","v":1}'
	check(bytes.decode_u32(0) == 0 and bytes.decode_u32(4) == body.length(), "the header says kind %d, %d bytes" % [bytes.decode_u32(0), bytes.decode_u32(4)])
	var parsed: Variant = JSON.parse_string(bytes.slice(8).get_string_from_utf8())
	check(parsed is Dictionary and parsed.client_id == "1", "the body came out as %s" % str(parsed))


func test_an_activity_says_where_he_is_with_a_button_to_get_the_game() -> void:
	var alone := DiscordPresence.activity("Freeing the sawpits", "Level 12", 1000, "liberation", "Liberation")
	check(alone.details == "Freeing the sawpits" and alone.state == "Level 12" and alone.timestamps.start == 1000, "the activity reads %s" % str(alone))
	check(alone.assets.small_image == "liberation" and alone.assets.large_image == "logo", "its pictures are %s" % str(alone.assets))
	check(alone.buttons[0].url == DiscordPresence.GET_THE_GAME and not alone.has("party"), "a run alone has a party, or no button to get the game")
	var crew := DiscordPresence.activity("Endless", "Level 4", 1000, "endless", "Endless", 3)
	check(crew.party.size == [3, 4], "a crew of three shows as %s" % str(crew.get("party")))


func test_it_tells_a_listening_discord_what_he_is_playing() -> void:
	var path := ProjectSettings.globalize_path("user://test_discord_ipc")
	DirAccess.remove_absolute(path)
	var discord := UDSServer.new()
	check(discord.listen(path) == OK, "the pretend Discord couldn't listen")
	var presence := DiscordPresence.new()
	presence.start([path])
	presence.show(DiscordPresence.activity("In the village", "", 1000, "village", "The village"), 0.0)
	var line := _accept(discord)
	check(line != null, "nobody came to the pretend Discord")
	if line != null:
		var handshake := _read(line)
		check(handshake.get("kind") == DiscordPresence.HANDSHAKE and handshake.get("body", {}).get("client_id") == DiscordPresence.APPLICATION, "the handshake was %s" % str(handshake))
		_write(line, DiscordPresence.FRAME, {"cmd": "DISPATCH", "evt": "READY"})
		var setting := _read(line)
		var args: Dictionary = setting.get("body", {}).get("args", {})
		check(setting.get("body", {}).get("cmd") == "SET_ACTIVITY" and args.get("activity", {}).get("details") == "In the village", "what was set was %s" % str(setting))
		check(args.get("pid") == OS.get_process_id(), "it didn't say which process is playing")
		_write(line, DiscordPresence.FRAME, {"cmd": "SET_ACTIVITY", "evt": null})
	presence.stop()
	discord.stop()
	DirAccess.remove_absolute(path)


func test_nothing_is_sent_more_often_than_discord_takes_it() -> void:
	var presence := DiscordPresence.new()
	var level_1 := DiscordPresence.activity("Endless", "Level 1", 1000, "endless", "Endless")
	var level_2 := DiscordPresence.activity("Endless", "Level 2", 1000, "endless", "Endless")
	presence.show(level_1, 0.0)
	presence.show(level_2, 5.0)
	check(presence._sent == level_1, "a new level was sent five seconds after the last")
	presence.show(level_2, DiscordPresence.EVERY + 0.1)
	check(presence._sent == level_2, "the new level wasn't sent once it was time")
	var home := DiscordPresence.activity("In the village", "", 1000, "village", "The village")
	presence.show(home, DiscordPresence.EVERY + 1.0)
	check(presence._sent == home, "going home wasn't said at once")


func _accept(server: UDSServer) -> StreamPeerUDS:
	for attempt in 300:
		if server.is_connection_available():
			return server.take_connection()
		OS.delay_msec(10)
	return null


func _read(line: StreamPeerUDS) -> Dictionary:
	var header := _take(line, 8)
	if header.size() < 8:
		return {}
	var body := _take(line, header.decode_u32(4))
	return {"kind": header.decode_u32(0), "body": JSON.parse_string(body.get_string_from_utf8())}


func _take(line: StreamPeerUDS, count: int) -> PackedByteArray:
	for attempt in 300:
		line.poll()
		if line.get_available_bytes() >= count:
			return line.get_data(count)[1]
		OS.delay_msec(10)
	return PackedByteArray()


func _write(line: StreamPeerUDS, kind: int, message: Dictionary) -> void:
	line.put_data(DiscordPresence.frame(kind, message))
