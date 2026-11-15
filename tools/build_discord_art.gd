extends SceneTree
## Draws the pictures Discord shows beside what someone's playing, from the game's own palette and
## pixels, enlarged by whole pixels: "logo", Tompel's face as on the icon; and the small ones in
## the corner, "village" (a hut on its stilts), "liberation" (a sapling coming up where the forest
## was cleared) and "endless" (a firefly's light). Run with:
## godot --headless --path . --script tools/build_discord_art.gd -- <folder>
## and upload them to the Discord application's Rich Presence art, under those names. They aren't
## kept in the repository: Discord keeps them.

const SIZE := 1024
## The small ones are seen in a circle: what's on them stays inside it.
const SMALL_SCALE := 44
const LOGO_SCALE := 52

const COLORS := {
	"k": Palette.OUTLINE, "Y": Palette.BRASS_LIGHT, "y": Palette.BRASS, "c": Palette.CREAM,
	"b": Palette.BARK, "B": Palette.BARK_LIGHT, "G": Palette.LEAF_LIGHT, "g": Palette.LEAF,
	"M": Palette.MUD_LIGHT, "m": Palette.MUD, "F": Palette.FIREFLY_GLOW, "W": Palette.FIREFLY,
}
const SMALL := {
	"village": [
		"................",
		".......kk.......",
		"......kYYk......",
		".....kYYYYk.....",
		"....kYYYYYYk....",
		"...kYYYYYYYYk...",
		"..kYYYYYYYYYYk..",
		".kyyyyyyyyyyyyk.",
		".kkkkkkkkkkkkkk.",
		"..kcccckkcccck..",
		"..kccckbbkccck..",
		"..kccckbbkccck..",
		"..kkkkkbbkkkkk..",
		"...kBk....kBk...",
		"...kBk....kBk...",
		"................",
	],
	"liberation": [
		"................",
		"......kkkk......",
		".....kGGGGk.....",
		"....kGGgGGGk....",
		"...kGGGGGgGGk...",
		"...kGgGGGGGGk...",
		"....kGGGGgGk....",
		".....kkbbkk.....",
		"......kbbk......",
		"......kbbk......",
		"......kbbk......",
		"....kkkbbkkk....",
		"...kMMMMMMMMk...",
		"..kMMmMMMMmMMk..",
		"..kkkkkkkkkkkk..",
		"................",
	],
	"endless": [
		"................",
		"................",
		".......k........",
		"......kFk.......",
		"......kFk.......",
		".....kFFFk......",
		"..kkkFFWFFkkk...",
		".kFFFFWWWFFFFk..",
		"..kkkFFWFFkkk...",
		".....kFFFk......",
		"......kFk.......",
		"......kFk.......",
		".......k........",
		"................",
		"................",
		"................",
	],
}


func _init() -> void:
	var arguments := OS.get_cmdline_user_args()
	var folder := arguments[0] if not arguments.is_empty() else "user://discord"
	DirAccess.make_dir_recursive_absolute(folder)
	_logo().save_png(folder.path_join("logo.png"))
	for name: String in SMALL:
		_small(SMALL[name]).save_png(folder.path_join(name + ".png"))
	print("logo, %s written to %s" % [", ".join(SMALL.keys()), folder])
	quit()


## Tompel's face, as the icon has it, on the jungle's two greens.
func _logo() -> Image:
	var face := Sprites.image(Sprites.coat(Sprites.cat_body_art("front", 0), "tompel", "front")).get_region(Rect2i(4, 2, 16, 13))
	var picture := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	picture.fill(Palette.JUNGLE)
	picture.fill_rect(Rect2i(0, int(SIZE * 0.62), SIZE, SIZE - int(SIZE * 0.62)), Palette.JUNGLE_DARK)
	face.resize(face.get_width() * LOGO_SCALE, face.get_height() * LOGO_SCALE, Image.INTERPOLATE_NEAREST)
	picture.blend_rect(face, Rect2i(Vector2i.ZERO, face.get_size()), Vector2i((SIZE - face.get_width()) / 2, (SIZE - face.get_height()) / 2 + 24))
	return picture


## One of the small ones: its pixels, centered on the jungle's dark green.
func _small(rows: Array) -> Image:
	var art := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in (rows[y] as String).length():
			var letter: String = rows[y][x]
			if COLORS.has(letter):
				art.set_pixel(x, y, COLORS[letter])
	var used := art.get_used_rect()
	art = art.get_region(used)
	art.resize(art.get_width() * SMALL_SCALE, art.get_height() * SMALL_SCALE, Image.INTERPOLATE_NEAREST)
	var picture := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	picture.fill(Palette.JUNGLE_DARK)
	picture.blend_rect(art, Rect2i(Vector2i.ZERO, art.get_size()), (Vector2i(SIZE, SIZE) - art.get_size()) / 2)
	return picture
