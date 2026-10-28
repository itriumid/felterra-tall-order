extends TestCase
## Playing online: what the host sends a guest arrives whole, the same objects are updated from one
## snapshot to the next, and once a guest has the world, a busy fight's snapshot is small enough to
## send 20 times a second.


## The host's world sent to a guest's arena by one guest's sender and receiver.
func _send(host: Arena, sender: Snapshot.Sender, receiver: Snapshot.Receiver, guest: Arena, events: Array[Dictionary] = []) -> Array[Dictionary]:
	return receiver.apply(sender.delta(Snapshot.take(host, events)), guest)


## A busy fight a minute in, two cats with something to fight with, giants and dogs about.
func _host() -> Arena:
	var arena := Arena.new(7)
	var first := arena.add_cat(Arena.SIZE / 2.0)
	var second := arena.add_cat(Arena.SIZE / 2.0 + Vector2(2.0, 0.0))
	second.coat = "gray"
	for cat in arena.cats:
		cat.health = 1.0e6
	first.wear({"weapons": ["nunchaku"]})
	for step in int(60.0 / Arena.STEP):
		arena.step()
	return arena


func test_the_guest_sees_what_the_host_has() -> void:
	var host := _host()
	var guest := Arena.new()
	var sender := Snapshot.Sender.new()
	var receiver := Snapshot.Receiver.new()
	_send(host, sender, receiver, guest)
	check(guest.cats.size() == 2, "%d cats came of 2" % guest.cats.size())
	check(guest.cats[1].coat == "gray", "the second cat came in a %s coat" % guest.cats[1].coat)
	check(guest.cats[0].weapons.size() == host.cats[0].weapons.size() and guest.cats[0].weapons[0].name == "nunchaku", "his nunchaku didn't come")
	check(guest.creatures.size() == host.creatures.size(), "%d of the horde came of %d" % [guest.creatures.size(), host.creatures.size()])
	check(guest.giants.size() == host.giants.size(), "%d giants came of %d" % [guest.giants.size(), host.giants.size()])
	check(guest.fallen.size() == host.fallen.size(), "%d of the fallen came of %d" % [guest.fallen.size(), host.fallen.size()])
	check(guest.kills == host.kills and guest.level == host.level and is_equal_approx(guest.time, host.time), "the score didn't come")
	var farthest := 0.0
	for index in host.creatures.size():
		farthest = maxf(farthest, host.creatures[index].body.position.distance_to(guest.creatures[index].body.position))
	check(farthest < 0.01, "a creature came %.3f m from where it is" % farthest)
	check(guest.cats[0].body.position.distance_to(host.cats[0].body.position) < 0.001, "he came somewhere else")


func test_the_same_objects_are_kept_from_one_snapshot_to_the_next() -> void:
	var host := _host()
	var guest := Arena.new()
	var sender := Snapshot.Sender.new()
	var receiver := Snapshot.Receiver.new()
	_send(host, sender, receiver, guest)
	var cat := guest.cats[0]
	var weapon := cat.weapons[0]
	var creature := guest.creatures[0]
	host.step()
	_send(host, sender, receiver, guest)
	check(guest.cats[0] == cat and guest.cats[0].weapons[0] == weapon, "his cat or his weapon was made anew")
	var id: int = receiver.objects.find_key(creature)
	var still_there := host.creatures.any(func(each: Creature) -> bool: return each.get_instance_id() == id)
	check(guest.creatures.has(creature) or not still_there, "a creature still there was made anew")
	var farthest := 0.0
	for index in host.creatures.size():
		farthest = maxf(farthest, host.creatures[index].body.position.distance_to(guest.creatures[index].body.position))
	check(farthest < 0.01, "after a step, a creature came %.3f m from where it is" % farthest)
	check(guest.cats[0].body.position.distance_to(host.cats[0].body.position) < 0.001, "after a step, he came somewhere else")


func test_what_the_host_lets_go_the_guest_lets_go() -> void:
	var host := _host()
	var guest := Arena.new()
	var sender := Snapshot.Sender.new()
	var receiver := Snapshot.Receiver.new()
	_send(host, sender, receiver, guest)
	host.creatures.clear()
	host.giants.clear()
	_send(host, sender, receiver, guest)
	check(guest.creatures.is_empty() and guest.giants.is_empty(), "the horde stayed on the guest's side")
	var still := receiver.objects.values().filter(func(object: Object) -> bool: return object is Creature or object is Giant)
	check(still.is_empty(), "%d gone from the host still kept" % still.size())


func test_events_come_with_it() -> void:
	var host := _host()
	var events: Array[Dictionary] = [{"position": Vector2(3, 4), "height": 0.2, "direction": Vector2.RIGHT, "killed": true, "by": "round", "giant": false, "kind": "rat"}]
	var came := _send(host, Snapshot.Sender.new(), Snapshot.Receiver.new(), Arena.new(), events)
	check(came.size() == 1 and came[0].by == "round" and came[0].position == Vector2(3, 4), "the events came as %s" % str(came))


func test_a_busy_fight_is_small_enough_to_send() -> void:
	var host := _host()
	var sender := Snapshot.Sender.new()
	var first := sender.delta(Snapshot.take(host, [])).size()
	# The next, three steps on: a twentieth of a second.
	var largest := 0
	for tick in 20:
		for step in 3:
			host.step()
		largest = maxi(largest, sender.delta(Snapshot.take(host, [])).size())
	print("      %d in the horde, %d fallen: the first snapshot %d bytes, then at most %d" % [host.creatures.size(), host.fallen.size(), first, largest])
	# 20 a second to each guest, under about 400 kilobits a second.
	check(largest < 2500, "a snapshot takes %d bytes" % largest)
