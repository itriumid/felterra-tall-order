class_name Overlay
extends Node2D
## The interface over the world: her health, level, dodge and aim at a glance; the cards she's
## holding; the choice a run starts with; the pause menu; and with F3, what the machine is doing.

const CARD_FRAMES: Array[Color] = [Palette.OFF_WHITE, Palette.LEAF_LIGHT, Palette.CLOTH_LIGHT, Palette.BRASS_LIGHT]
const CARD_SIZE := Vector2(150, 70)
## What each boss is called on its health bar.
const BOSS_NAMES := {
	"feller_buncher": "Feller buncher", "log_loader": "Log loader", "logging_truck": "Logging truck",
	"bulldozer": "Bulldozer", "helicopter": "Helicopter", "rat_baron": "The Rat Baron", "handler": "The Handler",
}
## How many of a shop's rows show at once, and how many lines its chosen thing's story gets.
const SHOP_ROWS_SHOWN := 13
const STORY_LINES := 3
const BOOK_LINES := 8
const AIM_NAMES := {"nearest": "Nearest", "toughest": "Toughest", "crowd": "Crowd"}

var arena: Arena
var cat: Cat
var show_numbers := false
## Waiting for the player to choose a weapon to start with, and the forged weapon offered beside
## the nunchaku and the handgun once the longhouse is restored ("" if none).
var choosing := false
var start_extra := ""
## Tab held: the cards' stats are explained. X held: picking banishes.
var reading := false
var banishing := false
## The pause menu's lines while it's open (empty when it isn't), and which is chosen.
var menu: Array[String] = []
var menu_choice := 0
## The settings page's rows while it's open (empty when it isn't), and which is chosen.
var setting_rows: Array[Dictionary] = []
var setting_choice := 0
## Which page the menu is ("title", "pause" or "summary"), the last run's numbers, and which of
## them beat the best.
var page := ""
var summary := {}
var beaten: Array[String] = []
var step_milliseconds := 0.0
## Where she is ("run", or "village" for the village and the walk into it), the village when
## she's there, and the line of the story's opening being written out, if one is.
var place := "run"
var village_map: VillageMap
var intro := ""
## A cutscene playing: its keys show along the bottom, so skipping it is never a secret.
var cutscene := false
## In the village: what's kept there (for its counts), what Enter does at the door she's at, a
## line the village has just said, and a shop's page while one is open.
var village_record: Village
var door := ""
var message := ""
var shop_page := ""
var shop_title := ""
var shop_rows: Array[Dictionary] = []
var shop_choice := 0
## A shop's tabs, if it has them (the smithy does), and the one showing; and where the next run
## goes, pinned on the map.
var shop_tabs: Array[String] = []
## Why the last thing chosen in a shop couldn't be done, if it couldn't ("" if it could).
var shop_note := ""
var shop_tab := 0
var next_run := ""
## A liberation run: its area's name ("" in Endless), and its goal's progress, done of all.
var area_name := ""
var goal := Vector2.ZERO
## Where the path out leads, for the hint by the gate.
var leads_to := "the clearing"


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if page == "title":
		_draw_title()
		if not setting_rows.is_empty():
			_draw_settings()
		return
	if place == "village":
		_draw_village()
		if not shop_rows.is_empty():
			_dither()
			if shop_page == "board":
				_draw_map()
			else:
				_draw_shop()
			return
		if not menu.is_empty():
			_dither()
			if not setting_rows.is_empty():
				_draw_settings()
			else:
				_draw_menu()
		return
	if not menu.is_empty():
		_dither()
	if cat == null:
		return
	if cutscene:
		# A story told over the run: the world held still, only the lines and their keys.
		_draw_cutscene()
		return
	_draw_status()
	_draw_score()
	_draw_boss()
	_draw_cage_markers()
	if show_numbers:
		_draw_numbers()
	if not setting_rows.is_empty():
		_draw_settings()
	elif page == "summary":
		_draw_summary()
	elif not menu.is_empty():
		_draw_menu()
	elif choosing:
		_draw_start()
	elif not cat.offers.is_empty():
		_draw_cards()


## Health, level and dodge as bars with their icons, and how her weapons choose.
func _draw_status() -> void:
	var box := Rect2(4, 4, 150, 44)
	InterfaceArt.panel(self, box)
	var x := box.position.x + 5
	var y := box.position.y + 5
	var sturdy := cat.health > 1000.0
	InterfaceArt.icon(self, Vector2(x, y), "health", Palette.SCARF_RED)
	InterfaceArt.bar(self, Rect2(x + 10, y + 1, 92, 5), 1.0 if sturdy else cat.health / cat.max_health, Palette.SCARF_RED)
	PixelFont.draw(self, Vector2(x + 106, y - 1), "Sturdy" if sturdy else "%d/%d" % [ceili(cat.health), roundi(cat.max_health)], Palette.OFF_WHITE)
	y += 11
	InterfaceArt.icon(self, Vector2(x, y), "level", Palette.BRASS_LIGHT)
	InterfaceArt.bar(self, Rect2(x + 10, y + 1, 92, 5), float(arena.experience) / Arena.experience_needed(arena.level), Palette.BRASS_LIGHT)
	PixelFont.draw(self, Vector2(x + 106, y - 1), "Level %d" % arena.level, Palette.OFF_WHITE)
	y += 11
	var ready := cat.dodge_charges >= 1.0
	var charges := cat.most_charges()
	InterfaceArt.icon(self, Vector2(x, y), "dodge", Palette.LEAF_LIGHT if ready else Palette.SMOKE)
	InterfaceArt.bar(self, Rect2(x + 10, y + 1, 40, 5), cat.dodge_charges / charges, Palette.LEAF_LIGHT if ready else Palette.SMOKE)
	# With more than one charge, the bar is cut into one stretch for each.
	for charge in range(1, charges):
		draw_rect(Rect2(x + 10 + roundf(40.0 * charge / charges), y + 1, 1, 5), Palette.PANEL_DARK)
	InterfaceArt.icon(self, Vector2(x + 58, y), "aim", Palette.OFF_WHITE)
	PixelFont.draw(self, Vector2(x + 68, y - 1), AIM_NAMES[cat.aim_mode], Palette.OFF_WHITE)
	InterfaceArt.key_cap(self, Vector2(box.end.x - 14, y - 2), "T")


## A story's line as it's written out, and the keys to hurry it or skip it.
func _draw_cutscene() -> void:
	var screen := get_viewport_rect().size
	if not intro.is_empty():
		_shadowed(intro, 46, Palette.OFF_WHITE)
	var keys: Array[String] = ["Esc", "skip"]
	if not intro.is_empty():
		keys = ["Enter", "next", "Esc", "skip"]
	var width := InterfaceArt.key_line_width(keys)
	InterfaceArt.key_line(self, Vector2(screen.x - width - 8, screen.y - 16), keys)


## In the village: the story's opening as it's told, the names of the cats near her, and once
## she's near the path out, where it goes.
func _draw_village() -> void:
	if village_map == null:
		return
	var screen := get_viewport_rect().size
	if cutscene:
		if not intro.is_empty():
			# Written over the scene, a shadow under each letter so it reads on leaves or earth.
			var at := Vector2(floorf((screen.x - PixelFont.width(intro)) / 2.0), 46)
			PixelFont.draw(self, at + Vector2(1, 1), intro, Palette.GRAPHITE)
			PixelFont.draw(self, at, intro, Palette.OFF_WHITE)
		var keys: Array[String] = ["Esc", "skip"]
		if not intro.is_empty():
			keys = ["Enter", "next", "Esc", "skip"]
		var width := InterfaceArt.key_line_width(keys)
		InterfaceArt.key_line(self, Vector2(screen.x - width - 8, screen.y - 16), keys)
		return
	if village_record != null:
		_draw_village_counts()
	_shadowed(message, screen.y - 38, Palette.PINK)
	if not door.is_empty():
		var keys: Array[String] = ["Enter", door]
		var width := InterfaceArt.key_line_width(keys)
		InterfaceArt.key_line(self, Vector2(floorf((screen.x - width) / 2.0), screen.y - 24), keys)
	var to_screen := get_viewport().get_canvas_transform()
	var her := village_map.cat.body.position
	for index in village_map.villagers.size():
		var villager := village_map.villagers[index]
		if villager.body.position.distance_to(her) > 1.6:
			continue
		var name: String = village_map.names[index]
		var above: Vector2 = to_screen * World.to_screen(villager.body.position, 0.6)
		var at := Vector2(floorf(above.x - PixelFont.width(name) / 2.0), floorf(above.y))
		PixelFont.draw(self, at + Vector2(1, 1), name, Palette.GRAPHITE)
		PixelFont.draw(self, at, name, Palette.PINK)
	if door.is_empty() and her.x > VillageMap.EXIT_FROM - 3.5 and her.y > VillageMap.PATH_TOP - 1.0 and her.y < VillageMap.PATH_BOTTOM + 1.0:
		var hint := "On along the path: to " + leads_to
		var at := Vector2(floorf((screen.x - PixelFont.width(hint)) / 2.0), screen.y - 24)
		PixelFont.draw(self, at + Vector2(1, 1), hint, Palette.GRAPHITE)
		PixelFont.draw(self, at, hint, Palette.OFF_WHITE)


## Text over the scene, centered, with a shadow under it so it reads on leaves or earth.
func _shadowed(text: String, y: float, color: Color) -> void:
	if text.is_empty():
		return
	var at := Vector2(floorf((get_viewport_rect().size.x - PixelFont.width(text)) / 2.0), y)
	PixelFont.draw(self, at + Vector2(1, 1), text, Palette.GRAPHITE)
	PixelFont.draw(self, at, text, color)


## What the village has: salvage, cloth, and its cats.
func _draw_village_counts() -> void:
	var counts := [["salvage", village_record.salvage, Palette.STEEL_LIGHT], ["cloth", village_record.cloth, Palette.PINK], ["cats", village_record.cats.size(), Palette.BRASS_LIGHT]]
	var box := Rect2(4, 4, 130, 18)
	InterfaceArt.panel(self, box)
	var x := box.position.x + 5
	for count: Array in counts:
		InterfaceArt.icon(self, Vector2(x, box.position.y + 5), count[0], count[2])
		PixelFont.draw(self, Vector2(x + 10, box.position.y + 4), str(count[1]), Palette.OFF_WHITE)
		x += 42


## A shop's page: what can be had, what each costs, and where it stands, as many rows as fit with
## the rest a scroll away; its tabs, if it has them; the story of what's chosen; what the village
## has to spend on top, and the keys below.
func _draw_shop() -> void:
	var screen := get_viewport_rect().size
	var row := PixelFont.LINE_HEIGHT + 3
	var width := 320.0
	var shown := mini(shop_rows.size(), SHOP_ROWS_SHOWN)
	var tabs_height := 16 if not shop_tabs.is_empty() else 0
	var has_stories := shop_rows.any(func(entry: Dictionary) -> bool: return not (entry.get("story", "") as String).is_empty())
	# The book's chapters are longer than a thing's story.
	var story_lines := BOOK_LINES if shop_page == "book" else STORY_LINES
	var story_height := story_lines * PixelFont.LINE_HEIGHT + 8 if has_stories else 0
	# A page with tabs keeps its size from tab to tab, however many each holds.
	var window := SHOP_ROWS_SHOWN if not shop_tabs.is_empty() else shown
	var height := 30 + tabs_height + window * row + 6 + story_height
	var box := Rect2(floorf((screen.x - width) / 2.0), floorf((screen.y - height) / 2.0) - 6, width, height)
	InterfaceArt.panel(self, box)
	InterfaceArt.bold(self, box.position + Vector2(10, 7), shop_title, Palette.PINK)
	if village_record != null and shop_page in ["forge", "looks"]:
		var have := "%d salvage, %d cloth" % [village_record.salvage, village_record.cloth]
		PixelFont.draw(self, Vector2(box.end.x - 10 - PixelFont.width(have), box.position.y + 7), have, Palette.SMOKE)
	var y := box.position.y + 24
	if not shop_tabs.is_empty():
		var x := box.position.x + 8
		for index in shop_tabs.size():
			var label := shop_tabs[index]
			var tab := Rect2(Vector2(x, y - 2), Vector2(PixelFont.width(label) + 8, PixelFont.LINE_HEIGHT + 2))
			if index == shop_tab:
				draw_rect(tab, Palette.PINK)
			PixelFont.draw(self, tab.position + Vector2(4, 2), label, Palette.GRAPHITE if index == shop_tab else Palette.SMOKE)
			x += tab.size.x + 4
		y += tabs_height
	# The window of rows keeps the chosen one in it.
	var first := clampi(shop_choice - shown / 2, 0, shop_rows.size() - shown)
	for index in range(first, first + shown):
		var entry: Dictionary = shop_rows[index]
		var at := Vector2(box.position.x + 6, y + 2 + (index - first) * row)
		var chosen := index == shop_choice
		if chosen:
			draw_rect(Rect2(at - Vector2(0, 2), Vector2(box.size.x - 12, row)), Palette.PINK)
		var ink := Palette.GRAPHITE if chosen else (Palette.OFF_WHITE if entry.can or entry.state in ["packed", "worn from the start"] else Palette.SMOKE)
		PixelFont.draw(self, at + Vector2(10, 0), entry.name, ink)
		PixelFont.draw(self, Vector2(box.end.x - 16 - PixelFont.width(entry.state), at.y), entry.state, ink)
	# More above or below, marked by an arrow in the middle of the window's edge.
	var middle := floorf(box.get_center().x)
	if first > 0:
		_arrow(Vector2(middle, y - 2), -1)
	if first + shown < shop_rows.size():
		_arrow(Vector2(middle, y + shown * row + 1), 1)
	if has_stories:
		var story_top := y + window * row + 6
		draw_rect(Rect2(box.position.x + 6, story_top - 3, box.size.x - 12, 1), Palette.PANEL_LIGHT)
		var lines := wrapped(shop_rows[shop_choice].get("story", ""), box.size.x - 24)
		for index in mini(lines.size(), story_lines):
			PixelFont.draw(self, Vector2(box.position.x + 12, story_top + 2 + index * PixelFont.LINE_HEIGHT), lines[index], Palette.CREAM)
	if not shop_note.is_empty():
		InterfaceArt.bold(self, Vector2(box.end.x - 10 - InterfaceArt.bold_width(shop_note), box.position.y + 7), shop_note, Palette.PINK)
	var keys: Array[String] = ["W S", "choose", "Enter", "take", "Esc", "back"]
	if not shop_tabs.is_empty():
		keys = ["A D", "tab", "W S", "choose", "Enter", "forge" if shop_page == "forge" else "pack or leave home", "Esc", "back"]
	elif shop_page == "book":
		keys = ["W S", "choose", "Esc", "back"]
	var keys_width := InterfaceArt.key_line_width(keys)
	InterfaceArt.key_line(self, Vector2(floorf((screen.x - keys_width) / 2.0), box.end.y + 6), keys)


## A small pink arrow, pointing up (-1) or down (1), its point at a spot.
func _arrow(point: Vector2, way: int) -> void:
	for step in 3:
		draw_rect(Rect2(point + Vector2(-step, -way * step), Vector2(step * 2 + 1, 1)), Palette.PINK)


## The board's map of the forest, and below it, where the chosen place is and how it stands.
func _draw_map() -> void:
	var screen := get_viewport_rect().size
	var box := Rect2(floorf((screen.x - 460) / 2.0), 24, 460, 300)
	InterfaceArt.panel(self, box)
	InterfaceArt.bold(self, box.position + Vector2(10, 7), shop_title, Palette.PINK)
	var map := Rect2(box.position + Vector2(8, 22), Vector2(box.size.x - 16, 230))
	ForestMap.draw(self, map, shop_rows, shop_choice, next_run)
	var chosen: Dictionary = shop_rows[shop_choice]
	var y := map.end.y + 8
	InterfaceArt.bold(self, Vector2(box.position.x + 12, y), chosen.name, Palette.OFF_WHITE)
	var going := "the next run goes here" if chosen.id == next_run else ""
	PixelFont.draw(self, Vector2(box.end.x - 12 - PixelFont.width(going), y), going, Palette.BRASS_LIGHT)
	PixelFont.draw(self, Vector2(box.position.x + 12, y + PixelFont.LINE_HEIGHT + 2), _sentence(chosen.state), Palette.LEAF_LIGHT if chosen.free else Palette.SMOKE)
	var keys: Array[String] = ["W A S D", "choose", "Enter", "go there", "Esc", "back"]
	var keys_width := InterfaceArt.key_line_width(keys)
	InterfaceArt.key_line(self, Vector2(floorf((screen.x - keys_width) / 2.0), box.end.y + 6), keys)


## A line with its first letter capitalized, and nothing else touched.
static func _sentence(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1)


## Text broken into lines no wider than a width, at the spaces.
static func wrapped(text: String, width: float) -> Array[String]:
	var lines: Array[String] = []
	var line := ""
	for word in text.split(" ", false):
		var longer := word if line.is_empty() else line + " " + word
		if PixelFont.width(longer) > width and not line.is_empty():
			lines.append(line)
			line = word
		else:
			line = longer
	if not line.is_empty():
		lines.append(line)
	return lines


## Cages out of sight: a mark at the edge of the screen, the way to each.
func _draw_cage_markers() -> void:
	var screen := get_viewport_rect()
	var to_screen := get_viewport().get_canvas_transform()
	for cage in arena.cages:
		if cage.opened:
			continue
		var at: Vector2 = to_screen * World.to_screen(cage.body.position, 0.25)
		if screen.grow(-4).has_point(at):
			continue
		var edge := at.clamp(Vector2(6, 54), screen.size - Vector2(13, 13))
		InterfaceArt.icon(self, edge.floor(), "cage", Palette.PINK)


## A machine at work: its name and its health, across the top of the screen.
## The boss, across the top of the screen: an area's once it comes, or in Endless, a machine at
## work. Until an area's boss comes, its goal is there instead.
func _draw_boss() -> void:
	var screen := get_viewport_rect().size
	var box := Rect2(floorf(screen.x / 2.0 - 90.0), 4, 180, 22)
	var boss: Object = arena.boss
	if boss == null:
		for machine in arena.machines:
			if machine.standing():
				boss = machine
	var standing: bool = boss != null and (boss.standing() if boss is Machine or boss is Giant else boss.alive())
	if standing:
		var most: float = boss.most_health if "most_health" in boss else boss.stat("health")
		InterfaceArt.panel(self, box)
		InterfaceArt.bold(self, box.position + Vector2(6, 3), BOSS_NAMES.get(boss.kind, boss.kind), Palette.OFF_WHITE)
		InterfaceArt.bar(self, Rect2(box.position + Vector2(6, 14), Vector2(box.size.x - 12, 5)), boss.health / most, Palette.HI_VIS)
		return
	if area_name.is_empty() or arena.goal_done:
		return
	var title: String = arena.area.goal.title
	var count := "%d:%02d left" % [int(goal.y - goal.x) / 60, int(goal.y - goal.x) % 60] if arena.area.goal.kind == "hold" else "%d of %d" % [goal.x, goal.y]
	InterfaceArt.panel(self, box)
	InterfaceArt.bold(self, box.position + Vector2(6, 3), title, Palette.OFF_WHITE)
	PixelFont.draw(self, Vector2(box.end.x - 6 - PixelFont.width(count), box.position.y + 3), count, Palette.LEAF_LIGHT)
	InterfaceArt.bar(self, Rect2(box.position + Vector2(6, 14), Vector2(box.size.x - 12, 5)), goal.x / maxf(goal.y, 1.0), Palette.LEAF_LIGHT)
	PixelFont.draw(self, Vector2(floorf(screen.x / 2.0 - PixelFont.width(area_name) / 2.0), box.end.y + 2), area_name, Palette.SMOKE)


func _draw_score() -> void:
	var screen := get_viewport_rect().size
	var kills := "%d" % arena.kills
	var time := "%d:%02d" % [int(arena.time) / 60, int(arena.time) % 60]
	var width := 10 + PixelFont.width(kills) + 12 + 10 + PixelFont.width(time) + 10
	var box := Rect2(screen.x - width - 4, 4, width, 18)
	InterfaceArt.panel(self, box)
	var x := box.position.x + 5
	InterfaceArt.icon(self, Vector2(x, box.position.y + 5), "kills", Palette.OFF_WHITE)
	PixelFont.draw(self, Vector2(x + 10, box.position.y + 4), kills, Palette.OFF_WHITE)
	x += 10 + PixelFont.width(kills) + 12
	InterfaceArt.icon(self, Vector2(x, box.position.y + 5), "time", Palette.OFF_WHITE)
	PixelFont.draw(self, Vector2(x + 10, box.position.y + 4), time, Palette.OFF_WHITE)


func _draw_numbers() -> void:
	var lines: Array[String] = [
		"%d frames a second, a step takes %.2f ms" % [Engine.get_frames_per_second(), step_milliseconds],
		"%d in the horde, %d fallen, %d rounds in the air" % [arena.creatures.size(), arena.fallen.size(), arena.shots.size()],
	]
	var width := 0
	for line in lines:
		width = maxi(width, PixelFont.width(line))
	var box := Rect2(4, 52, width + 10, lines.size() * PixelFont.LINE_HEIGHT + 8)
	InterfaceArt.panel(self, box)
	for index in lines.size():
		PixelFont.draw(self, box.position + Vector2(5, 4 + index * PixelFont.LINE_HEIGHT), lines[index], Palette.OFF_WHITE)


## The oldest offer held, as three cards along the bottom.
func _draw_cards() -> void:
	var offer: Array = cat.offers[0]
	var screen := get_viewport_rect().size
	var gap := 8.0
	var total := offer.size() * CARD_SIZE.x + (offer.size() - 1) * gap
	var x := floorf((screen.x - total) / 2.0)
	var y := screen.y - CARD_SIZE.y - 6
	var explained: Array[String] = []
	for index in offer.size():
		var choice: Dictionary = offer[index]
		var card := Upgrades.describe(choice)
		_draw_card(Rect2(x, y, CARD_SIZE.x, CARD_SIZE.y), str(index + 1), choice.rarity, card)
		for line: String in card.explain:
			if not line in explained:
				explained.append(line)
		x += CARD_SIZE.x + gap
	var keys: Array[String] = []
	if banishing:
		keys.append_array(["X", "and a number banishes"])
	else:
		keys.append_array(["R", "reroll (%d)" % cat.rerolls, "Tab", "read", "X", "banish"])
	if cat.offers.size() > 1:
		keys.append_array(["", "%d more held" % (cat.offers.size() - 1)])
	var line_width := InterfaceArt.key_line_width(keys)
	InterfaceArt.key_line(self, Vector2(floorf((screen.x - line_width) / 2.0), y - 15), keys)
	if reading:
		_draw_explained(explained, y - 20)


## One card: the rarity's ribbon, frame and pips; the key that plays it; a picture of what it is;
## its name, and what it gives.
func _draw_card(box: Rect2, key: String, rarity: int, card: Dictionary) -> void:
	var color: Color = CARD_FRAMES[rarity]
	InterfaceArt.panel(self, box)
	_rarity_frame(box, rarity)
	# The ribbon: the rarity in words, on its own color.
	var ribbon := Rect2(box.position + Vector2(2, 2), Vector2(box.size.x - 4, 11))
	draw_rect(ribbon, color)
	PixelFont.draw(self, ribbon.position + Vector2(14, 1), card.get("ribbon", Upgrades.RARITY_NAMES[rarity]), Palette.GRAPHITE)
	for pip in rarity + 1:
		draw_rect(Rect2(ribbon.end.x - 5 - pip * 4, ribbon.position.y + 4, 2, 3), Palette.GRAPHITE)
	# The key that plays it, on pink.
	var badge := Rect2(box.position + Vector2(2, 2), Vector2(10, 11))
	draw_rect(badge, Palette.PINK)
	PixelFont.draw(self, badge.position + Vector2(3, 1), key, Palette.GRAPHITE)
	# The picture, sunk into the card.
	var picture := Rect2(box.position + Vector2(5, 17), Vector2(26, 22))
	InterfaceArt.well(self, picture)
	var preview := Sprites.preview(card.item)
	draw_texture(preview, (picture.position + (picture.size - preview.get_size()) / 2.0).floor())
	var text_x := picture.end.x + 5
	InterfaceArt.bold(self, Vector2(text_x, box.position.y + 18), card.name, Palette.OFF_WHITE)
	for index in (card.lines as Array).size():
		PixelFont.draw(self, Vector2(text_x, box.position.y + 30 + index * PixelFont.LINE_HEIGHT), card.lines[index], Palette.LEAF_LIGHT)
	if card.unfamiliar:
		PixelFont.draw(self, Vector2(box.end.x - 9, box.end.y - 13), "?", Palette.PINK)


## Rarity in the frame's shape, not just its color: common plain, uncommon with its corners cut,
## rare doubled, legendary heavy with its corners filled.
func _rarity_frame(box: Rect2, rarity: int) -> void:
	var color: Color = CARD_FRAMES[rarity]
	draw_rect(box, color, false, 1.0)
	if rarity >= Upgrades.Rarity.RARE:
		draw_rect(box.grow(1), color, false, 1.0)
	if rarity == Upgrades.Rarity.UNCOMMON:
		for corner in [box.position, Vector2(box.end.x - 1, box.position.y), Vector2(box.position.x, box.end.y - 1), box.end - Vector2.ONE]:
			draw_rect(Rect2(corner, Vector2.ONE), Palette.PANEL_DARK)
	if rarity == Upgrades.Rarity.LEGENDARY:
		for corner in [box.position, Vector2(box.end.x - 3, box.position.y), Vector2(box.position.x, box.end.y - 3), box.end - Vector2(3, 3)]:
			draw_rect(Rect2(corner - Vector2.ONE, Vector2(4, 4)), color)


## What the stats on the cards mean, one line each.
func _draw_explained(lines: Array[String], bottom: float) -> void:
	var width := 0
	for line in lines:
		width = maxi(width, PixelFont.width(line))
	var screen := get_viewport_rect().size
	var height := lines.size() * PixelFont.LINE_HEIGHT + 10
	var box := Rect2(floorf((screen.x - width - 12) / 2.0), bottom - height - 4, width + 12, height)
	InterfaceArt.panel(self, box)
	for index in lines.size():
		var parts := lines[index].split(": ", true, 1)
		InterfaceArt.bold(self, box.position + Vector2(6, 5 + index * PixelFont.LINE_HEIGHT), parts[0] + ":", Palette.PINK)
		if parts.size() > 1:
			PixelFont.draw(self, box.position + Vector2(6 + InterfaceArt.bold_width(parts[0] + ":") + 4, 5 + index * PixelFont.LINE_HEIGHT), parts[1], Palette.OFF_WHITE)


## The choice a run starts with, as two cards.
func _draw_start() -> void:
	var screen := get_viewport_rect().size
	var title := "Choose what you start with"
	var cards := [
		{"name": "Nunchaku", "item": "nunchaku", "ribbon": "Melee", "lines": ["Go Chuck Purris", "style"], "unfamiliar": false},
		{"name": "Handgun", "item": "handgun", "ribbon": "Ranged", "lines": ["Go John Whisker", "style"], "unfamiliar": false},
	]
	if not start_extra.is_empty():
		cards.append({"name": Upgrades.WEAPON_NAMES[start_extra], "item": start_extra, "ribbon": "Forged", "lines": ["From the smithy", "A or D: another"], "unfamiliar": false})
	var gap := 10.0
	var total := cards.size() * CARD_SIZE.x + (cards.size() - 1) * gap
	var top := floorf(screen.y / 2.0 - CARD_SIZE.y / 2.0)
	var frame := Rect2(floorf((screen.x - total) / 2.0) - 10, top - 24, total + 20, CARD_SIZE.y + 34)
	InterfaceArt.panel(self, frame)
	InterfaceArt.bold(self, Vector2(floorf((screen.x - InterfaceArt.bold_width(title)) / 2.0), top - 18), title, Palette.PINK)
	for index in cards.size():
		_draw_card(Rect2(frame.position.x + 10 + index * (CARD_SIZE.x + gap), top, CARD_SIZE.x, CARD_SIZE.y), str(index + 1), Upgrades.Rarity.COMMON, cards[index])


## The see-through panel behind the menu: a checkerboard of palette pixels, not a blend.
func _dither() -> void:
	var screen := get_viewport_rect().size
	for y in int(screen.y):
		for x in range(y % 2, int(screen.x), 2):
			draw_rect(Rect2(x, y, 1, 1), Palette.GRAPHITE)


## The pause menu, and beside it the cards she's holding, to read but not to play. In the
## village there's no run, so no cards: the menu sits in the middle on its own.
func _draw_menu() -> void:
	var screen := get_viewport_rect().size
	var title := "Paused"
	var width := InterfaceArt.bold_width(title)
	for line in menu:
		width = maxi(width, PixelFont.width(line) + 14)
	var row := PixelFont.LINE_HEIGHT + 3
	var held_width := _held_width() if cat != null else 0.0
	var left := screen.x - held_width - 12 if cat != null else screen.x
	var box := Rect2(floorf(left / 2.0 - width / 2.0) - 10, floorf(screen.y / 2.0 - (menu.size() * row + 24) / 2.0), width + 20, menu.size() * row + 28)
	InterfaceArt.panel(self, box)
	InterfaceArt.bold(self, box.position + Vector2(10, 7), title, Palette.PINK)
	for index in menu.size():
		var at := box.position + Vector2(6, 22 + index * row)
		if index == menu_choice:
			# The chosen row on pink, its text in graphite.
			draw_rect(Rect2(at - Vector2(0, 2), Vector2(box.size.x - 12, row)), Palette.PINK)
			PixelFont.draw(self, at + Vector2(2, 0), "→", Palette.GRAPHITE)
			PixelFont.draw(self, at + Vector2(12, 0), menu[index], Palette.GRAPHITE)
		else:
			PixelFont.draw(self, at + Vector2(12, 0), menu[index], Palette.OFF_WHITE)
	if cat != null:
		_draw_held(Vector2(screen.x - held_width - 6, box.position.y))


func _held_lines() -> Array[String]:
	var lines: Array[String] = []
	for offer: Array in cat.offers.slice(0, 3):
		for choice: Dictionary in offer:
			var card := Upgrades.describe(choice)
			lines.append("%s (%s): %s" % [card.name, Upgrades.RARITY_NAMES[choice.rarity].to_lower(), ", ".join(card.lines).to_lower()])
		lines.append("")
	if lines.is_empty():
		lines.append("None yet")
	else:
		lines[-1] = "Played in action, with 1, 2 and 3"
	return lines


func _held_width() -> float:
	var width := InterfaceArt.bold_width("Cards held: %d" % cat.offers.size())
	for line in _held_lines():
		width = maxi(width, PixelFont.width(line))
	return width + 20


func _draw_held(at: Vector2) -> void:
	var lines := _held_lines()
	var title := "Cards held: %d" % cat.offers.size()
	var box := Rect2(at, Vector2(_held_width(), lines.size() * PixelFont.LINE_HEIGHT + 28))
	InterfaceArt.panel(self, box)
	InterfaceArt.bold(self, box.position + Vector2(10, 7), title, Palette.PINK)
	for index in lines.size():
		PixelFont.draw(self, box.position + Vector2(10, 22 + index * PixelFont.LINE_HEIGHT), lines[index], Palette.OFF_WHITE)


## The settings page: each section's rows, the value on the right, a volume as a bar of ten. The
## chosen row is on pink, with the arrows that change it.
func _draw_settings() -> void:
	var screen := get_viewport_rect().size
	var row_height := PixelFont.LINE_HEIGHT + 2
	var sections := {}
	for row in setting_rows:
		if row.section != "":
			sections[row.section] = true
	var width := 260.0
	# Rows, a heading and a gap for each section, a gap before Back, the title and the margins.
	var height := setting_rows.size() * row_height + sections.size() * (row_height + 4) + 4 + 30
	var box := Rect2(floorf((screen.x - width) / 2.0), floorf((screen.y - height) / 2.0), width, height)
	InterfaceArt.panel(self, box)
	InterfaceArt.bold(self, box.position + Vector2(10, 7), "Settings", Palette.PINK)
	var y := box.position.y + 24
	var section := "none"
	for index in setting_rows.size():
		var row: Dictionary = setting_rows[index]
		if row.section != section:
			section = row.section
			y += 4
			if section != "":
				PixelFont.draw(self, Vector2(box.position.x + 10, y), section.capitalize(), Palette.PINK)
				y += row_height
		var chosen := index == setting_choice
		var ink := Palette.GRAPHITE if chosen else Palette.OFF_WHITE
		if chosen:
			draw_rect(Rect2(box.position.x + 6, y - 2, box.size.x - 12, row_height), Palette.PINK)
		PixelFont.draw(self, Vector2(box.position.x + 16, y), row.name, ink)
		var right := box.end.x - 14
		if row.volume >= 0:
			var bar_x: float = right - 10 * 6 - (12 if chosen else 0)
			for step in 10:
				var filled: bool = step < int(row.volume)
				draw_rect(Rect2(bar_x + step * 6, y + 1, 4, 5), (Palette.GRAPHITE if chosen else Palette.LEAF_LIGHT) if filled else (Palette.PANEL_LIGHT if not chosen else Palette.SMOKE))
			if chosen:
				PixelFont.draw(self, Vector2(bar_x - 10, y), "←", ink)
				PixelFont.draw(self, Vector2(right - 7, y), "→", ink)
		elif row.value != "":
			var value: String = ("← %s →" % row.value) if chosen and not row.get("action", false) else String(row.value)
			PixelFont.draw(self, Vector2(right - PixelFont.width(value), y), value, ink)
		y += row_height
	var keys: Array[String] = ["W S", "choose", "A D", "change", "Esc", "back"]
	var line_width := InterfaceArt.key_line_width(keys)
	InterfaceArt.key_line(self, Vector2(floorf((screen.x - line_width) / 2.0), box.end.y + 6), keys)


## The title: the game's name over the clearing, and its choices.
func _draw_title() -> void:
	var screen := get_viewport_rect().size
	var heading := "Felterra"
	var title := "Tall Order"
	var line := "A crew of cats against giants"
	var row := PixelFont.LINE_HEIGHT + 3
	var width := maxf(InterfaceArt.bold_width(title) + 40, PixelFont.width(line) + 24)
	for choice in menu:
		width = maxf(width, PixelFont.width(choice) + 40)
	var height := 52 + menu.size() * row + 10
	var box := Rect2(floorf((screen.x - width) / 2.0), floorf(screen.y * 0.42 - height / 2.0), width, height)
	if not setting_rows.is_empty():
		return
	InterfaceArt.panel(self, box)
	var center := box.position.x + box.size.x / 2.0
	PixelFont.draw(self, Vector2(floorf(center - PixelFont.width(heading) / 2.0), box.position.y + 8), heading, Palette.OFF_WHITE)
	InterfaceArt.bold(self, Vector2(floorf(center - InterfaceArt.bold_width(title) / 2.0), box.position.y + 20), title, Palette.PINK)
	PixelFont.draw(self, Vector2(floorf(center - PixelFont.width(line) / 2.0), box.position.y + 33), line, Palette.SMOKE)
	_draw_choices(Vector2(box.position.x + 6, box.position.y + 52), box.size.x - 12)
	var keys: Array[String] = ["W S", "choose", "Enter", "take"]
	var keys_width := InterfaceArt.key_line_width(keys)
	InterfaceArt.key_line(self, Vector2(floorf((screen.x - keys_width) / 2.0), box.end.y + 6), keys)


## How the run went, what beat the best, and where to go from here.
func _draw_summary() -> void:
	var screen := get_viewport_rect().size
	var rows := [
		["time", "Survived", "%d:%02d" % [int(summary.get("time", 0.0)) / 60, int(summary.get("time", 0.0)) % 60]],
		["level", "Level reached", str(summary.get("level", 1))],
		["kills", "Kills", str(summary.get("kills", 0))],
		["giants", "Giants felled", str(summary.get("giants", 0))],
		["machines", "Machines broken", str(summary.get("machines", 0))],
		["rescued", "Cats rescued", str(summary.get("rescued", 0))],
		["salvage", "Salvage", str(summary.get("salvage", 0))],
	]
	# What freeing the area taught her, the first time.
	var learned: Array = summary.get("learned", [])
	if not learned.is_empty():
		rows.append(["learned", "Learned", ", ".join(learned)])
	var row_height := PixelFont.LINE_HEIGHT + 2
	var width := 260.0 if not learned.is_empty() else 220.0
	# The heading, the numbers, a gap, the choices, and the margin below.
	var height := 26 + rows.size() * row_height + 8 + menu.size() * (PixelFont.LINE_HEIGHT + 3) + 2
	var box := Rect2(floorf((screen.x - width) / 2.0), floorf((screen.y - height) / 2.0), width, height)
	InterfaceArt.panel(self, box)
	var freed: String = summary.get("freed", "")
	InterfaceArt.bold(self, box.position + Vector2(10, 7), ("Freed: " + freed) if not freed.is_empty() else "She's down", Palette.LEAF_LIGHT if not freed.is_empty() else Palette.PINK)
	var y := box.position.y + 26
	for row: Array in rows:
		PixelFont.draw(self, Vector2(box.position.x + 14, y), row[1], Palette.OFF_WHITE)
		var value: String = row[2]
		var right := box.end.x - 14
		if row[0] in beaten:
			# A new best, marked in words as well as color.
			var mark := "New best"
			PixelFont.draw(self, Vector2(right - PixelFont.width(value) - PixelFont.width(mark) - 8, y), mark, Palette.PINK)
		InterfaceArt.bold(self, Vector2(right - InterfaceArt.bold_width(value), y), value, Palette.LEAF_LIGHT if row[0] in beaten else Palette.OFF_WHITE)
		y += row_height
	_draw_choices(Vector2(box.position.x + 6, y + 8), box.size.x - 12)


## A page's choices, the chosen one on pink with graphite text.
func _draw_choices(at: Vector2, width: float) -> void:
	var row := PixelFont.LINE_HEIGHT + 3
	for index in menu.size():
		var spot := at + Vector2(0, index * row)
		if index == menu_choice:
			draw_rect(Rect2(spot - Vector2(0, 2), Vector2(width, row)), Palette.PINK)
			PixelFont.draw(self, spot + Vector2(4, 0), "→", Palette.GRAPHITE)
			PixelFont.draw(self, spot + Vector2(14, 0), menu[index], Palette.GRAPHITE)
		else:
			PixelFont.draw(self, spot + Vector2(14, 0), menu[index], Palette.OFF_WHITE)
