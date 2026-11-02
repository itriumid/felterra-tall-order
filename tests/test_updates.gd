extends TestCase
## The title says when there's a newer version: only for a version that really is newer, only with
## a page that's safe to open, and never on an answer it can't read. And playing together, which of
## two players on different versions is behind.

const MINE := "0.0.5"


## What the title would be told, for an answer from the service.
func _found(status: int, body: String) -> Array:
	var told: Array = []
	var updates := Updates.new()
	updates.found.connect(func(version: String, page: String) -> void: told.append([version, page]))
	updates._answered(HTTPRequest.RESULT_SUCCESS, status, PackedStringArray(), body.to_utf8_buffer())
	updates.free()
	return told


func test_a_newer_version_is_told_with_its_page() -> void:
	var mine: String = ProjectSettings.get_setting("application/config/version")
	var newer := "%d.0.0" % (mine.get_slice(".", 0).to_int() + 1)
	var told := _found(200, JSON.stringify({"version": newer, "page": "https://itrium.id/tall-order"}))
	check(told == [[newer, "https://itrium.id/tall-order"]], "told %s" % str(told))


func test_the_same_or_an_older_version_is_not_told() -> void:
	var mine: String = ProjectSettings.get_setting("application/config/version")
	check(_found(200, JSON.stringify({"version": mine, "page": "https://itrium.id/tall-order"})).is_empty(), "this version was told as newer")
	check(_found(200, JSON.stringify({"version": "0.0.1", "page": "https://itrium.id/tall-order"})).is_empty(), "an older version was told as newer")


func test_nothing_is_told_from_an_answer_it_cannot_trust() -> void:
	check(_found(503, "").is_empty(), "told something from a failed answer")
	check(_found(200, "not JSON").is_empty(), "told something from an answer that isn't one")
	check(_found(200, JSON.stringify({"version": "99.0.0", "page": "file:///etc/passwd"})).is_empty(), "offered a page that isn't on the web")
	check(_found(200, JSON.stringify({"version": 99})).is_empty(), "told a version that isn't one")


func test_versions_are_compared_number_by_number() -> void:
	check(Online.older("0.0.5", "0.0.10"), "0.0.10 came before 0.0.5")
	check(not Online.older("0.1.0", "0.0.9"), "0.1.0 came before 0.0.9")
	check(not Online.older(MINE, MINE), "a version came before itself")
	check(Online.older("0.9.9", "1.0.0"), "1.0.0 came before 0.9.9")
