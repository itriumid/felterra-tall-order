class_name Areas
extends RefCounted
## Liberation: the forest, area by area, from the village's edge to the airstrip. Each area is one
## run with a shape: push in through what holds it, do what only that place asks (break the nests,
## free the caged, wreck the saws), and then its boss comes; beat the boss and the area is free,
## and the next one opens. The story is told going into each area and coming home from it.
##
## The cats don't know at first what's wrong with the forest. They find out as they go: rats where
## there never were any, then cages, then a giant with a whistle, then the sawpits and the sign
## over the gate. It was always humans: a company, PT Makmur Bakti Gemilang, which the cats call
## Makmur Bakar, clearing the forest as the official partner of an agency that has stamped it
## "idle land", for the nation's food. All of them made up; the way it goes, less so.
##
## Endless is the other way to play: the clearing, a fresh one every run, the horde growing until
## he's down. Its plan is the arena's own (Arena.ENDLESS).

## The company, as its signs give it and as the cats call it; the agency it's partnered with; and
## what its site boards say.
const COMPANY := "PT Makmur Bakti Gemilang"
const NICKNAME := "Makmur Bakar"
const AGENCY := "the Food Land Acceleration Agency"
const SLOGAN := "Building a Greener Tomorrow!"
const BOARD := "From Idle Land to Plenty"

## The areas, in the order they're freed. Each: its name; the look of its ground; what spawns there
## (a plan like Endless's, only what that place has); its goal, and where the goal's things stand,
## in meters; its boss and where it comes from; the story going in and coming home; and what
## freeing it the first time brings the village. And the send-off, the first time he leaves for it;
## what's told going back in with its goal done on an earlier run; and the cat who teaches him its
## dodge mutations, at home, once it's freed. And its ground plan: how big it is, where he stands
## once he's walked in, what stands where for good, and what's scattered about it (trees, stumps),
## placed from the area's own seed so it's the same every time. A line is told over the scene, or said by a cat in it,
## as {by, text}: "elder", or a villager's name.
const LIST: Array[Dictionary] = [
	{
		"id": "edge", "name": "The village's edge", "ground": "edge",
		"size": Vector2(40.0, 24.0), "start": Vector2(20.0, 12.0),
		"obstacles": [{"kind": "trunk", "rect": Rect2(12.0, 15.5, 4.5, 0.55)}, {"kind": "trunk", "rect": Rect2(26.0, 15.0, 4.0, 0.55)}],
		"scatter": [{"kind": "tree", "count": 9, "radius": [0.45, 0.65]}, {"kind": "bush", "count": 12, "radius": [0.45, 0.8]}],
		"plan": {"rats": {"rate": 1.2, "growth": 0.03}},
		"goal": {"kind": "structures", "structure": "nest", "title": "Break the nests",
			"at": [Vector2(8.0, 6.0), Vector2(32.0, 7.0), Vector2(20.0, 19.0)]},
		"boss": {"kind": "creature", "type": "rat_baron", "at": Vector2(20.0, 2.0), "tip": "It calls the rats in: cut it down before the crowd builds"},
		"before": [
			"The rats are thickest just past the last huts.",
			"They're gathering around something. Feeding on it.",
			"Find what's drawing them, and break it open.",
		],
		"after": [
			"The crates were stamped with marks none of us could read.",
			"Whoever left them there, it wasn't a rat.",
			"Their tracks lead deeper into the forest.",
			"And under the Rat Baron's nest, a cage: Pak Besi, the smith, his hammer taken.",
		],
		"send_off": [
			"The Elder walks you to the gate.",
			{"by": "elder", "text": "Just past the last huts. Look, and come home."},
		],
		"again": ["The nests are still broken. Only the Rat Baron is left."],
		"teaches": {"by": "elder", "mutations": ["rolling_slash", "land_on_feet"], "lines": [
			{"by": "elder", "text": "Rats don't stamp crates. I should have taught you this before you went."},
			{"by": "elder", "text": "Never just get out of the way. Roll through, blade out."},
			{"by": "elder", "text": "And when you fall, fall rolling."},
		]},
		"frees": [{"name": "Pak Besi", "coat": "black"}], "bonus": 15,
	},
	{
		"id": "deep", "name": "The deep forest", "ground": "deep",
		"size": Vector2(44.0, 28.0), "start": Vector2(22.0, 14.0),
		"obstacles": [{"kind": "trunk", "rect": Rect2(8.0, 12.0, 5.0, 0.55)}, {"kind": "trunk", "rect": Rect2(30.0, 16.0, 5.0, 0.55)}, {"kind": "trunk", "rect": Rect2(18.0, 22.0, 4.5, 0.55)}],
		"scatter": [{"kind": "tree", "count": 30, "radius": [0.5, 0.85]}, {"kind": "bush", "count": 14, "radius": [0.5, 0.9]}],
		"plan": {"rats": {"rate": 1.4, "growth": 0.04}, "dogs": {"from": 30.0, "interval": 30.0, "pack": 3, "most": 9}},
		"goal": {"kind": "cages", "title": "Free the caged",
			"at": [Vector2(6.0, 5.0), Vector2(38.0, 5.0), Vector2(7.0, 23.0), Vector2(37.0, 23.0)]},
		"boss": {"kind": "giant", "type": "handler", "at": Vector2(22.0, 1.0), "tip": "He keeps his distance and whistles dogs in: run him down"},
		"before": [
			"Deeper in, the forest goes quiet. Too quiet.",
			"Stumps, cut flat. Mud churned into ruts as wide as a hut.",
			"And cats in cages. Our cats.",
			"Get them out.",
		],
		"after": [
			"We saw one. A giant, on two legs, with a whistle.",
			"The dogs answered to him as if he owned them.",
			"He wore that same bright orange as their harnesses.",
			"Whatever this is, it's bigger than rats.",
			"Nenek Pus was in the last cage, and she wants it known she could have got out herself.",
		],
		"send_off": [
			{"by": "elder", "text": "Deeper than any of us forage now. Bring back whoever you find."},
		],
		"again": ["The cages stand open, as you left them. Only the Handler is left."],
		"teaches": {"by": "Nenek Pus", "mutations": ["pounce", "riposte"], "lines": [
			"Nenek Pus is stiff from the cage, but not too stiff to show off.",
			{"by": "Nenek Pus", "text": "Over the crowd, onto the one that matters."},
			{"by": "Nenek Pus", "text": "And let them swing first. Be there after."},
		]},
		"frees": [{"name": "Nenek Pus", "coat": "gray"}], "bonus": 20,
	},
	{
		"id": "sawpits", "name": "The sawpits", "ground": "sawpits",
		"size": Vector2(40.0, 24.0), "start": Vector2(20.0, 12.0),
		# The cut trunks stacked in rows, with the saws in the lanes between.
		"obstacles": [
			{"kind": "log_stack", "rect": Rect2(4.0, 11.5, 5.0, 1.4)}, {"kind": "log_stack", "rect": Rect2(31.0, 11.5, 5.0, 1.4)},
			{"kind": "log_stack", "rect": Rect2(13.0, 6.0, 4.5, 1.4)}, {"kind": "log_stack", "rect": Rect2(22.5, 6.0, 4.5, 1.4)},
			{"kind": "log_stack", "rect": Rect2(5.0, 18.0, 5.0, 1.4)}, {"kind": "log_stack", "rect": Rect2(30.0, 18.0, 5.0, 1.4)},
			{"kind": "log_stack", "rect": Rect2(13.0, 20.5, 4.0, 1.4)}, {"kind": "log_stack", "rect": Rect2(23.0, 20.5, 4.0, 1.4)},
		],
		"scatter": [{"kind": "stump", "count": 12, "radius": [0.3, 0.45]}],
		"plan": {"rats": {"rate": 1.5, "growth": 0.04}, "dogs": {"from": 40.0, "interval": 35.0, "pack": 3, "most": 9},
			"giants": {"from": 20.0, "interval": 35.0, "most": 3, "chainsaw_from": 60.0, "chainsaw_every": 2}},
		"goal": {"kind": "structures", "structure": "saw", "title": "Wreck the saws",
			"at": [Vector2(10.0, 8.0), Vector2(30.0, 8.0), Vector2(20.0, 17.0)]},
		"boss": {"kind": "machine", "type": "feller_buncher", "at": Vector2(20.0, 1.8), "tip": "Its jaws come down where their shadow falls: be elsewhere"},
		"before": [
			"We followed the ruts to a noise like the whole forest screaming.",
			"Saws. Logs stacked higher than the trees they were.",
			"And a sign over the gate: %s. Official partner of %s." % [COMPANY, AGENCY],
			"\"%s\", more like: prosperity by burning." % NICKNAME,
			"It's humans. It was always humans.",
		],
		"after": [
			"\"%s\" That's what the sign says." % SLOGAN,
			"Green on the sign. Ash behind it.",
			"Their machines came up from a clearing to the east. That's where we go.",
			"Si Belang comes out from under the saw bench, sawdust to the ears.",
		],
		"send_off": [
			{"by": "Nenek Pus", "text": "Follow the ruts. Whatever made them, it isn't small."},
		],
		"again": ["The saws are still in pieces. Only the feller buncher is left."],
		"teaches": {"by": "Si Belang", "mutations": ["ankle_cutter", "caltrops"], "lines": [
			"Si Belang worked the sawpits' scraps for a season, and watched the giants the whole time.",
			{"by": "Si Belang", "text": "Their boots are slow to turn. Go between them, and cut."},
			{"by": "Si Belang", "text": "And leave them these. Bent nails, a pocketful."},
		]},
		"frees": [{"name": "Si Belang", "coat": "cream"}], "bonus": 30,
		"props": [{"kind": "sign", "at": Vector2(20.0, 3.4), "lines": [COMPANY, "Official partner of %s" % AGENCY, SLOGAN]}],
	},
	{
		"id": "clearing", "name": "The logged clearing", "ground": "clearing",
		"size": Vector2(48.0, 28.0), "start": Vector2(24.0, 14.0),
		"obstacles": [{"kind": "log_stack", "rect": Rect2(8.0, 4.0, 5.0, 1.4)}, {"kind": "log_stack", "rect": Rect2(35.0, 22.0, 5.0, 1.4)}],
		"scatter": [{"kind": "stump", "count": 40, "radius": [0.3, 0.45]}],
		"plan": {"rats": {"rate": 1.6, "growth": 0.05}, "dogs": {"from": 30.0, "interval": 30.0, "pack": 3, "most": 12},
			"giants": {"from": 15.0, "interval": 30.0, "most": 3, "chainsaw_from": 45.0, "chainsaw_every": 2},
			"cages": {"from": 30.0, "interval": 60.0, "most": 2}},
		"goal": {"kind": "hold", "seconds": 180.0, "title": "Hold the clearing"},
		"boss": {"kind": "machine", "type": "log_loader", "at": Vector2(46.0, 14.0), "tip": "It throws logs where you stand: keep moving"},
		"before": [
			"This was the old fig grove. You can count the stumps from the ridge.",
			"Hold the clearing. Show them we're not leaving.",
		],
		"after": [
			"The loader's arm is still twitching. It'll stop.",
			"The logs they cut go somewhere. Downhill, toward the river.",
			"Jingga was up the last fig tree all along, watching everything.",
		],
		"send_off": [
			{"by": "Si Belang", "text": "East, where the machines came from. Mind the big ones."},
		],
		"again": ["You held it once. Only the log loader is left."],
		"teaches": {"by": "Jingga", "mutations": ["long_leap", "dust_cloud"], "lines": [
			"Jingga has never once used the bridge over the stream.",
			{"by": "Jingga", "text": "Why would you? Run, and leave the ground."},
			{"by": "Jingga", "text": "And when you land, kick. They can't bite what they can't see."},
		]},
		"frees": [{"name": "Jingga", "coat": "orange"}], "bonus": 40,
	},
	{
		"id": "slide", "name": "The log slide", "ground": "slide",
		# Long and narrow, down the hill: three chutes under the levers, and rocks between them,
		# where the logs don't come.
		"size": Vector2(26.0, 36.0), "start": Vector2(13.0, 20.0),
		"obstacles": [
			{"kind": "rock", "at": Vector2(8.75, 9.0), "radius": 0.6}, {"kind": "rock", "at": Vector2(17.25, 13.0), "radius": 0.6},
			{"kind": "rock", "at": Vector2(8.75, 17.0), "radius": 0.6}, {"kind": "rock", "at": Vector2(17.25, 22.0), "radius": 0.6},
			{"kind": "rock", "at": Vector2(8.75, 26.0), "radius": 0.6}, {"kind": "rock", "at": Vector2(17.25, 30.0), "radius": 0.6},
		],
		"plan": {"rats": {"rate": 1.6, "growth": 0.05}, "dogs": {"from": 30.0, "interval": 30.0, "pack": 3, "most": 12},
			"giants": {"from": 15.0, "interval": 30.0, "most": 4, "chainsaw_from": 30.0, "chainsaw_every": 2}},
		"goal": {"kind": "levers", "title": "Pull the levers",
			"at": [Vector2(4.5, 1.6), Vector2(13.0, 1.6), Vector2(21.5, 1.6)]},
		"boss": {"kind": "machine", "type": "logging_truck", "at": Vector2(13.0, 34.0), "tip": "It charges, then stalls with its tank open: hit the tank"},
		"before": [
			"They slide the trunks down to the river on a chute of mud.",
			"Stacks of logs wait at the top, held back by levers.",
			"A lever is just a door that wants to fall. Pull them.",
		],
		"after": [
			"One truck less on the river road.",
			"Its driver ran for the offices on the hill.",
			"Kopi and Susu climb out of the cab, arguing about who drove better.",
		],
		"send_off": [
			{"by": "Jingga", "text": "Downhill to the river. Try not to ride a log down there."},
		],
		"again": ["The levers are still pulled. Only the logging truck is left."],
		"teaches": {"by": "Kopi", "mutations": ["more_charges", "slipstream"], "lines": [
			"Kopi and Susu never sit still. Not since the cage.",
			{"by": "Kopi", "text": "Keep up with us for a week and you won't either."},
			{"by": "Susu", "text": "Run in my wake. I'll pull you along."},
		]},
		"frees": [{"name": "Kopi", "coat": "black"}, {"name": "Susu", "coat": "cream"}], "bonus": 50,
	},
	{
		"id": "offices", "name": "The company's offices", "ground": "offices",
		# Cabins in two rows either side, the yard down the middle.
		"size": Vector2(44.0, 28.0), "start": Vector2(22.0, 14.0),
		"obstacles": [
			{"kind": "cabin", "rect": Rect2(2.0, 6.0, 5.0, 3.0)}, {"kind": "cabin", "rect": Rect2(10.0, 6.0, 5.0, 3.0)},
			{"kind": "cabin", "rect": Rect2(29.0, 6.0, 5.0, 3.0)}, {"kind": "cabin", "rect": Rect2(37.0, 6.0, 5.0, 3.0)},
			{"kind": "cabin", "rect": Rect2(2.0, 17.0, 5.0, 3.0)}, {"kind": "cabin", "rect": Rect2(10.0, 17.0, 5.0, 3.0)},
			{"kind": "cabin", "rect": Rect2(29.0, 17.0, 5.0, 3.0)}, {"kind": "cabin", "rect": Rect2(37.0, 17.0, 5.0, 3.0)},
			{"kind": "crates", "rect": Rect2(17.5, 8.5, 2.0, 1.2)}, {"kind": "crates", "rect": Rect2(25.0, 19.0, 2.0, 1.2)},
		],
		"plan": {"rats": {"rate": 1.4, "growth": 0.05}, "dogs": {"from": 20.0, "interval": 25.0, "pack": 4, "most": 16},
			"giants": {"from": 10.0, "interval": 25.0, "most": 4, "chainsaw_from": 20.0, "chainsaw_every": 2}},
		"goal": {"kind": "structures", "structure": "generator", "title": "Cut the power",
			"at": [Vector2(7.0, 12.5), Vector2(37.0, 12.5), Vector2(22.0, 4.0)]},
		"boss": {"kind": "machine", "type": "bulldozer", "at": Vector2(22.0, 25.5), "tip": "Only the engine at its back can be hurt: get behind it"},
		"before": [
			"Cabins in rows. Lights that hum all night. Maps on every wall.",
			"Our forest is on those maps, stamped: idle land. %s" % BOARD,
			"Cut the power, and let's see their permits in the dark.",
		],
		"after": [
			"Every permit said the same: the rest of it, next season, for the nation's food.",
			"An official flies in to the airstrip to cut the ribbon.",
			"Bu Jamu was locked in the canteen. She has opinions about the canteen.",
		],
		"send_off": [
			"Kopi and Susu walk you to the gate, arguing about which of them saw the hill first.",
		],
		"again": ["The generators are still dead. Only the bulldozer is left."],
		"teaches": {"by": "Bu Jamu", "mutations": ["lick_your_wounds", "scent_trail"], "lines": [
			"Bu Jamu looks you over, and tuts.",
			{"by": "Bu Jamu", "text": "Tend to your wounds as you go. You can fuss later."},
			{"by": "Bu Jamu", "text": "And leave the dogs something to follow that isn't you. They love my turmeric."},
		]},
		"frees": [{"name": "Bu Jamu", "coat": "cream"}], "bonus": 60,
		"props": [{"kind": "sign", "at": Vector2(13.0, 2.6), "lines": [BOARD, SLOGAN]}, {"kind": "sign", "at": Vector2(31.0, 2.6), "lines": ["Concession: idle land", COMPANY]}],
	},
	{
		"id": "airstrip", "name": "The airstrip", "ground": "airstrip",
		# Wide open, the hangar at the far end and nowhere much to hide.
		"size": Vector2(60.0, 24.0), "start": Vector2(30.0, 12.0),
		"obstacles": [
			{"kind": "hangar", "rect": Rect2(3.0, 1.0, 9.0, 5.0)}, {"kind": "tank", "at": Vector2(54.0, 18.0), "radius": 1.0},
			{"kind": "crates", "rect": Rect2(46.0, 6.0, 2.4, 1.2)}, {"kind": "crates", "rect": Rect2(14.0, 7.0, 2.4, 1.2)},
		],
		"plan": {"rats": {"rate": 1.6, "growth": 0.06}, "dogs": {"from": 20.0, "interval": 25.0, "pack": 4, "most": 16},
			"giants": {"from": 10.0, "interval": 22.0, "most": 5, "chainsaw_from": 10.0, "chainsaw_every": 2}},
		"goal": {"kind": "structures", "structure": "fuel", "title": "Cut the fuel lines",
			"at": [Vector2(7.0, 19.0), Vector2(52.0, 4.0), Vector2(30.0, 20.0)]},
		"boss": {"kind": "machine", "type": "helicopter", "at": Vector2(30.0, 12.0), "tip": "Out of reach in the air: hit it when it lands to unload"},
		"before": [
			"The ribbon is already strung across the airstrip.",
			"Ground the helicopter, and there's no one to cut it.",
		],
		"after": [
			"The ribbon never got cut. The last of them left by the river road, on foot.",
			"They'll be back one day. Giants are stubborn.",
			"But they'll have to take us seriously now.",
			"It was a tall order. We filled it.",
		],
		"send_off": [
			"The whole village comes to the gate.",
			{"by": "elder", "text": "There's a ribbon out there that mustn't get cut."},
		],
		"again": ["The fuel lines are still cut. Only the helicopter is left."],
		"teaches": {"by": "Datuk", "mutations": ["chain_roll"], "lines": [
			"Datuk was a ferry hand on the river before the cage, and never wasted a move.",
			{"by": "Datuk", "text": "Finish one roll, start the next. A roll that ends in a fall is half a roll."},
		]},
		"frees": [{"name": "Datuk", "coat": "gray"}], "bonus": 80,
		"props": [{"kind": "ribbon", "at": Vector2(30.0, 12.0)}, {"kind": "sign", "at": Vector2(30.0, 8.6), "lines": ["Grand opening", BOARD]}],
	},
	{
		# After a quiet, the forest's spirits come for the village: they think the cats burned the
		# forest. The run is the village itself, its houses standing where they stand; he comes
		# back in through the gate, and the roofs are alight.
		"id": "siege", "name": "The village, besieged", "ground": "village", "in_the_village": true,
		"size": VillageMap.SIZE, "start": Vector2(30.5, 9.0), "enters_from": Vector2.RIGHT,
		"plan": {"rats": {"rate": 1.3, "growth": 0.04, "kinds": {"wisp": 5, "tuyul": 1, "pocong": 2}},
			"packs": [{"kind": "monkey", "from": 30.0, "interval": 30.0, "pack": 3, "most": 9}, {"kind": "sapling", "from": 50.0, "interval": 40.0, "pack": 3, "most": 9}]},
		"goal": {"kind": "fires", "title": "Put out the fires", "well": VillageMap.WELL,
			"roofs": ["longhouse", "healer", "hut_0", "market"], "lit_at_start": 2, "light_every": 20.0},
		"boss": {"kind": "guardian", "type": "tiger", "at": Vector2(25.5, 1.4), "tip": "Its pounce lands where you stood: move, then hit it while it gathers itself"},
		"before": [
			"Lights come out of the trees, low and orange, and drift over the huts.",
			"Where they touch the thatch, it catches.",
			"Water from the well, a bucket at a time: get the fires out.",
			"And something big is watching from the forest.",
		],
		"after": [
			"The great tiger lies down in the square, and the lights go out, one by one.",
			"It is Inyiak Balang, the forest's grandfather, older than the village.",
			"The forest burned, it says, and wherever it burned, it found cats.",
			"The Elder shows it the company's cans from the sawpits, stamped MBG. Makmur Bakar.",
			"Inyiak Balang knows that smell. It's in every burned grove.",
			"Groves are still sick with it, it says, and their spirits can't rest.",
			"It will raise a shrine here, by the gate. Through it, the way to those groves.",
		],
		"send_off": [
			"Halfway to the gate, Jogiboy stops dead, his ears up.",
			{"by": "jogiboy", "text": "Smoke. Not out there. Behind us!"},
		],
		"again": ["The fires are out. Only Inyiak Balang is left."],
		"frees": [], "bonus": 100,
	},
]

## Endless, once the forest's spirits are friends: a corrupted grove, a fresh one every run, to be
## cleansed of what the company left. Each grove is one of these, laid out from the run's own
## seed: its look, its size, and what stands in it.
const GROVES: Array[Dictionary] = [
	{
		"id": "sick_grove", "name": "A sick grove", "ground": "deep", "size": Vector2(44.0, 28.0),
		"scatter": [{"kind": "tree", "count": 24, "radius": [0.5, 0.85]}, {"kind": "bush", "count": 12, "radius": [0.5, 0.9]}],
	},
	{
		"id": "burned_peat", "name": "The burned peat", "ground": "peat", "size": Vector2(48.0, 28.0),
		"scatter": [{"kind": "stump", "count": 30, "radius": [0.3, 0.5]}, {"kind": "tree", "count": 6, "radius": [0.45, 0.6]}, {"kind": "rock", "count": 5, "radius": [0.4, 0.7]}],
	},
	{
		"id": "riverbank", "name": "The riverbank", "ground": "riverbank", "size": Vector2(52.0, 24.0),
		"obstacles": [{"kind": "water", "rect": Rect2(0.0, 24.0 - 1.75, 52.0, 1.75)}],
		"scatter": [{"kind": "tree", "count": 10, "radius": [0.45, 0.7]}, {"kind": "bush", "count": 16, "radius": [0.45, 0.8]}, {"kind": "rock", "count": 8, "radius": [0.4, 0.8]}],
	},
]
## What comes at him in a grove: the restless spirits, and the company's machines, left behind
## and still working, with something else at the controls. The company's traps are still there too,
## with cats in them.
const GROVE_PLAN := {
	"rats": {"rate": 1.4, "growth": 0.05, "kinds": {"wisp": 5, "tuyul": 1, "pocong": 2}},
	"packs": [{"kind": "sapling", "from": 40.0, "interval": 35.0, "pack": 4, "most": 12}, {"kind": "monkey", "from": 60.0, "interval": 30.0, "pack": 3, "most": 9}],
	"machines": {"from": 300.0, "interval": 300.0, "kind": "feller_buncher"},
	"cages": {"from": 40.0, "interval": 75.0, "most": 2},
}


## The grove a run's seed lays out: one of the groves, as an area to stand in.
static func grove(seed_value: int) -> Dictionary:
	var chosen: Dictionary = GROVES[absi(seed_value) % GROVES.size()].duplicate()
	chosen.start = chosen.size / 2.0
	chosen.seed = seed_value
	return chosen


## How far scattered things keep from where things happen (where he stands, the goal's things, the
## boss's way in, the props), from the jungle's edge, and from each other, in meters; and how far
## to his left is kept open, for the way he walks in.
const KEEP_CLEAR := 2.2
const KEEP_FROM_EDGE := 1.5
const KEEP_APART := 1.4
const WAY_IN := 7.0


## What stands in an area, for good and scattered, as obstacles.
static func obstacles(area: Dictionary) -> Array[Obstacle]:
	var standing: Array[Obstacle] = []
	for entry: Dictionary in area.get("obstacles", []):
		standing.append(Obstacle.from(entry))
	if area.get("in_the_village", false):
		return VillageMap.standing()
	var size: Vector2 = area.get("size", Arena.SIZE)
	var start: Vector2 = area.get("start", size / 2.0)
	var clear: Array[Vector2] = [start]
	if area.has("boss"):
		clear.append(area.boss.at)
	if area.has("goal"):
		clear.append_array(area.goal.get("at", []))
	for prop: Dictionary in area.get("props", []):
		clear.append(prop.at)
	var random := RandomNumberGenerator.new()
	# An area is the same every time; a grove, as the run's seed has it.
	random.seed = area.get("seed", absi(hash(area.id)))
	for scattered: Dictionary in area.get("scatter", []):
		var placed := 0
		for attempt in scattered.count * 30:
			if placed >= scattered.count:
				break
			var radius := random.randf_range(scattered.radius[0], scattered.radius[1])
			var at := Vector2(random.randf_range(KEEP_FROM_EDGE + radius, size.x - KEEP_FROM_EDGE - radius), random.randf_range(KEEP_FROM_EDGE + radius, size.y - KEEP_FROM_EDGE - radius))
			if clear.any(func(spot: Vector2) -> bool: return spot.distance_to(at) < KEEP_CLEAR + radius):
				continue
			if absf(at.y - start.y) < 1.0 + radius and at.x < start.x + 1.0 and at.x > start.x - WAY_IN:
				continue
			if standing.any(func(other: Obstacle) -> bool: return other.contains(at, radius + KEEP_APART)):
				continue
			standing.append(Obstacle.from({"kind": scattered.kind, "at": at, "radius": radius}))
			placed += 1
	return standing


## An area by its id, or nothing.
static func named(id: String) -> Dictionary:
	for area in LIST:
		if area.id == id:
			return area
	return {}


## The dodge mutations an area's freeing teaches, by id, if any.
static func teaches(id: String) -> Array[String]:
	var mutations: Array[String] = []
	mutations.assign(named(id).get("teaches", {}).get("mutations", []))
	return mutations


static func ids() -> Array[String]:
	var all: Array[String] = []
	for area in LIST:
		all.append(area.id)
	return all
