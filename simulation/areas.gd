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
## she's down. Its plan is the arena's own (Arena.ENDLESS).

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
## freeing it the first time brings the village. And the send-off, the first time she leaves for it;
## and the cat who teaches her what freeing it shows them, its dodge mutations, over the story
## home.
const LIST: Array[Dictionary] = [
	{
		"id": "edge", "name": "The village's edge", "ground": "edge",
		"plan": {"rats": {"rate": 1.2, "growth": 0.03}},
		"goal": {"kind": "structures", "structure": "nest", "title": "Break the nests",
			"at": [Vector2(8.0, 6.0), Vector2(32.0, 7.0), Vector2(20.0, 19.0)]},
		"boss": {"kind": "creature", "type": "rat_baron", "at": Vector2(20.0, 2.0)},
		"before": [
			"The rats are thickest just past the last huts.",
			"They're gathering around something. Feeding on it.",
			"Find what's drawing them, and break it open.",
		],
		"after": [
			"The crates were stamped with marks none of us could read.",
			"Whoever left them there, it wasn't a rat.",
			"Their tracks lead deeper into the forest.",
		],
		"send_off": [
			"The elder walks you to the gate. \"Just past the last huts. Look, and come home.\"",
		],
		"teaches": {"by": "the elder", "mutations": ["rolling_slash", "land_on_feet"], "lines": [
			"Home again, the elder takes you out to the long grass.",
			"\"Never just get out of the way. Roll through, blade out. And when you fall, fall rolling.\"",
		]},
		"frees": [], "bonus": 15,
	},
	{
		"id": "deep", "name": "The deep forest", "ground": "deep",
		"plan": {"rats": {"rate": 1.4, "growth": 0.04}, "dogs": {"from": 30.0, "interval": 30.0, "pack": 3, "most": 9}},
		"goal": {"kind": "cages", "title": "Free the caged",
			"at": [Vector2(6.0, 5.0), Vector2(34.0, 5.0), Vector2(7.0, 19.0), Vector2(33.0, 19.0)]},
		"boss": {"kind": "giant", "type": "handler", "at": Vector2(20.0, 1.0)},
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
		],
		"send_off": [
			"\"Deeper than any of us forage now,\" the elder says. \"Bring back whoever you find.\"",
		],
		"teaches": {"by": "Nenek Pus", "mutations": ["pounce", "riposte"], "lines": [
			"Nenek Pus is stiff from the cage, but not too stiff to show off.",
			"\"Over the crowd, onto the one that matters. And let them swing first; be there after.\"",
		]},
		"frees": [{"name": "Nenek Pus", "coat": "gray"}, {"name": "Jingga", "coat": "orange"}], "bonus": 20,
	},
	{
		"id": "sawpits", "name": "The sawpits", "ground": "sawpits",
		"plan": {"rats": {"rate": 1.5, "growth": 0.04}, "dogs": {"from": 40.0, "interval": 35.0, "pack": 3, "most": 9},
			"giants": {"from": 20.0, "interval": 35.0, "most": 3, "chainsaw_from": 60.0, "chainsaw_every": 2}},
		"goal": {"kind": "structures", "structure": "saw", "title": "Wreck the saws",
			"at": [Vector2(10.0, 8.0), Vector2(30.0, 8.0), Vector2(20.0, 17.0)]},
		"boss": {"kind": "machine", "type": "feller_buncher", "at": Vector2(20.0, 1.8)},
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
		],
		"send_off": [
			"Nenek Pus sees you off. \"Follow the ruts. Whatever made them, it isn't small.\"",
		],
		"teaches": {"by": "Si Belang", "mutations": ["ankle_cutter", "caltrops"], "lines": [
			"Si Belang worked the sawpits' scraps for a season, and watched the giants the whole time.",
			"\"Their boots are slow to turn. Go between them, and cut.\"",
			"He empties his pockets: bent nails, by the handful. \"And leave them these.\"",
		]},
		"frees": [{"name": "Si Belang", "coat": "cream"}], "bonus": 30,
		"props": [{"kind": "sign", "at": Vector2(20.0, 3.4), "lines": [COMPANY, "Official partner of %s" % AGENCY, SLOGAN]}],
	},
	{
		"id": "clearing", "name": "The logged clearing", "ground": "clearing",
		"plan": {"rats": {"rate": 1.6, "growth": 0.05}, "dogs": {"from": 30.0, "interval": 30.0, "pack": 3, "most": 12},
			"giants": {"from": 15.0, "interval": 30.0, "most": 3, "chainsaw_from": 45.0, "chainsaw_every": 2},
			"cages": {"from": 30.0, "interval": 60.0, "most": 2}},
		"goal": {"kind": "hold", "seconds": 180.0, "title": "Hold the clearing"},
		"boss": {"kind": "machine", "type": "log_loader", "at": Vector2(37.0, 12.0)},
		"before": [
			"This was the old fig grove. You can count the stumps from the ridge.",
			"Hold the clearing. Show them we're not leaving.",
		],
		"after": [
			"The loader's arm is still twitching. It'll stop.",
			"The logs they cut go somewhere. Downhill, toward the river.",
		],
		"send_off": [
			"Si Belang points east. \"Where the machines came from. Mind the big ones.\"",
		],
		"teaches": {"by": "Jingga", "mutations": ["long_leap", "dust_cloud"], "lines": [
			"Jingga has never once used the bridge over the stream.",
			"\"Why would you? Run, and leave the ground. Everything down there is slower than you.\"",
			"\"And when you land, kick. They can't bite what they can't see.\"",
		]},
		"frees": [], "bonus": 40,
	},
	{
		"id": "slide", "name": "The log slide", "ground": "slide",
		"plan": {"rats": {"rate": 1.6, "growth": 0.05}, "dogs": {"from": 30.0, "interval": 30.0, "pack": 3, "most": 12},
			"giants": {"from": 15.0, "interval": 30.0, "most": 4, "chainsaw_from": 30.0, "chainsaw_every": 2}},
		"goal": {"kind": "levers", "title": "Pull the levers",
			"at": [Vector2(8.0, 1.6), Vector2(20.0, 1.6), Vector2(32.0, 1.6)]},
		"boss": {"kind": "machine", "type": "logging_truck", "at": Vector2(37.0, 20.0)},
		"before": [
			"They slide the trunks down to the river on a chute of mud.",
			"Stacks of logs wait at the top, held back by levers.",
			"A lever is just a door that wants to fall. Pull them.",
		],
		"after": [
			"One truck less on the river road.",
			"Its driver ran for the offices on the hill.",
		],
		"send_off": [
			"\"Downhill to the river,\" says Jingga. \"Try not to ride a log down there.\"",
		],
		"teaches": {"by": "Kopi and Susu", "mutations": ["more_charges", "slipstream"], "lines": [
			"Kopi and Susu never sit still. Not since the cage.",
			"Keep up with them for a week, and you won't either.",
			"They run in each other's wake, and show you how to pull a friend along in yours.",
		]},
		"frees": [{"name": "Kopi", "coat": "black"}, {"name": "Susu", "coat": "cream"}], "bonus": 50,
	},
	{
		"id": "offices", "name": "The company's offices", "ground": "offices",
		"plan": {"rats": {"rate": 1.4, "growth": 0.05}, "dogs": {"from": 20.0, "interval": 25.0, "pack": 4, "most": 16},
			"giants": {"from": 10.0, "interval": 25.0, "most": 4, "chainsaw_from": 20.0, "chainsaw_every": 2}},
		"goal": {"kind": "structures", "structure": "generator", "title": "Cut the power",
			"at": [Vector2(7.0, 12.0), Vector2(33.0, 12.0), Vector2(20.0, 4.0)]},
		"boss": {"kind": "machine", "type": "bulldozer", "at": Vector2(20.0, 22.0)},
		"before": [
			"Cabins in rows. Lights that hum all night. Maps on every wall.",
			"Our forest is on those maps, stamped: idle land. %s" % BOARD,
			"Cut the power, and let's see their permits in the dark.",
		],
		"after": [
			"Every permit said the same: the rest of it, next season, for the nation's food.",
			"An official flies in to the airstrip to cut the ribbon.",
		],
		"send_off": [
			"Kopi and Susu walk you to the gate, arguing about which of them saw the hill first.",
		],
		"teaches": {"by": "Nenek Pus", "mutations": ["lick_your_wounds", "scent_trail"], "lines": [
			"Nenek Pus says she's too old to teach anything else. Then she does.",
			"\"Tend to your wounds as you go. And leave the dogs something to follow that isn't you.\"",
		]},
		"frees": [], "bonus": 60,
		"props": [{"kind": "sign", "at": Vector2(12.0, 2.6), "lines": [BOARD, SLOGAN]}, {"kind": "sign", "at": Vector2(28.0, 2.6), "lines": ["Concession: idle land", COMPANY]}],
	},
	{
		"id": "airstrip", "name": "The airstrip", "ground": "airstrip",
		"plan": {"rats": {"rate": 1.6, "growth": 0.06}, "dogs": {"from": 20.0, "interval": 25.0, "pack": 4, "most": 16},
			"giants": {"from": 10.0, "interval": 22.0, "most": 5, "chainsaw_from": 10.0, "chainsaw_every": 2}},
		"goal": {"kind": "structures", "structure": "fuel", "title": "Cut the fuel lines",
			"at": [Vector2(6.0, 4.0), Vector2(34.0, 4.0), Vector2(20.0, 20.0)]},
		"boss": {"kind": "machine", "type": "helicopter", "at": Vector2(20.0, 12.0)},
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
			"\"There's a ribbon to not get cut,\" the elder says.",
		],
		"teaches": {"by": "Datuk", "mutations": ["chain_roll"], "lines": [
			"Datuk was a ferry hand on the river before the cage, and never wasted a move.",
			"\"Finish one, start the next. A roll that ends in a fall is half a roll.\"",
		]},
		"frees": [{"name": "Datuk", "coat": "gray"}], "bonus": 80,
		"props": [{"kind": "ribbon", "at": Vector2(20.0, 12.0)}, {"kind": "sign", "at": Vector2(20.0, 8.6), "lines": ["Grand opening", BOARD]}],
	},
]


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
