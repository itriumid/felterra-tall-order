class_name Areas
extends RefCounted
## Liberation: the forest, area by area, from the village's edge to the airstrip. Each area is one
## run with a shape: push in through what holds it, do what only that place asks (break the nests,
## free the caged, wreck the saws), and then its boss comes; beat the boss and the area is free,
## and the next one opens. The story is told going into each area and coming home from it.
##
## The cats don't know at first what's wrong with the forest. They find out as they go: rats where
## there never were any, then cages, then a giant with a whistle, then the sawpits and the sign
## over the gate. It was always humans: a company, Bright Future Timber, which the cats call Burnt
## Future, logging the forest as the official partner of an agency that has stamped it "idle land",
## for the nation's food. What nobody sees until the siege: the rats at the edge were never
## nesting. They dig the drains that dry the peat so it burns, for the Free Float, their nation,
## which sells the burned land on. All of them made up; the way it goes, less so.
##
## Endless is the other way to play: the clearing, a fresh one every run, the horde growing until
## he's down. Its plan is the arena's own (Arena.ENDLESS).

## The company, as its signs give it and as the cats call it; the agency it's partnered with; and
## what its site boards say.
const COMPANY := "Bright Future Timber"
const NICKNAME := "Burnt Future"
const AGENCY := "the Food Land Acceleration Agency"
const SLOGAN := "Building a Greener Tomorrow!"
const BOARD := "From Idle Land to Plenty"

## Writing is the one bridge between the cats and the giants, and it only goes one way: a cat who's
## eaten enough fish out of newspaper can read what humans write, and no human has ever read
## anything of a cat's. So each area the company holds has a piece of its writing lying in it, a
## paper, for him to bring home: Granny Whiskers reads it, and keeps a word from it. With the words
## from these five she can write, in the giants' own letters, what the cats have to say; the
## airstrip's own paper is only read after.
const WRITING: Array[String] = ["deep", "sawpits", "clearing", "slide", "offices"]
## What the five words say, put in order.
const SIGN := "NOT IDLE. CATS LIVE HERE."
## Said at the weaver's hut once she has all five.
const FIVE_WORDS := "CATS. IDLE. NOT. HERE. LIVE. Granny Whiskers lays them out in a row and moves them about for a long time. \"Patch,\" she says at last. \"How much white paint have we got?\""
## The sign going up after all, when the airstrip was freed before she had the words for it.
const SIGN_LATER: Array = [
	"Patch and Granny Whiskers went out to the airstrip with the white paint, and were gone all day.",
	"Across the runway, a paw wide, in the giants' own letters: NOT IDLE. CATS LIVE HERE.",
	{"by": "Granny Whiskers", "mood": "determined", "text": "They'll fly over it sooner or later. Let them say they couldn't read it."},
	{"by": "tompel", "mood": "happy", "text": "You spelled it right?"},
	{"by": "Granny Whiskers", "mood": "neutral", "text": "I spelled it twice."},
]

## The areas, in the order they're freed. Each: its name; the look of its ground; what spawns there
## (a plan like Endless's, only what that place has); its goal, and where the goal's things stand,
## in meters; its boss and where it comes from; the story going in and coming home; and what
## freeing it the first time brings the village. And the send-off, the first time he leaves for it;
## what's told going back in with its goal done on an earlier run; and the cat who teaches him its
## dodge mutations, at home, once it's freed. And its ground plan: how big it is, where he stands
## once he's walked in, what stands where for good, and what's scattered about it (trees, stumps),
## placed from the area's own seed so it's the same every time. A line is told over the scene, or said by a cat in it,
## as {by, text, mood}: "elder", "tompel", "jogiboy", or a villager's name. The story is the Elder's
## book, so a line told over the scene is "we", in the past tense.
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
			"Past the last huts, the ground was dry and warm, which it shouldn't have been after the rain.",
			"The rats were all over a few mounds of dirt, digging, going in and out.",
			"We took them for nests.",
		],
		"after": [
			"Under the biggest mound were crates, tins, and a lot of loose dirt.",
			"The tins had marks on them none of us could read.",
			"And in a cage behind the mounds sat Uncle Anvil, very cross, on top of his hammer.",
			{"by": "Uncle Anvil", "mood": "determined", "text": "They wanted it. I sat on it for nine days."},
			{"by": "tompel", "mood": "surprised", "text": "Nine days?"},
			{"by": "Uncle Anvil", "mood": "sad", "text": "Eight. I lost count. Is there any rice?"},
		],
		"send_off": [
			{"by": "elder", "mood": "worried", "text": "The rats are worst past the drying racks. Don't be a hero about it."},
		],
		"again": ["The nests are still broken. Only the Rat Baron is left."],
		"teaches": {"by": "elder", "mutations": ["rolling_slash", "land_on_feet"], "lines": [
			{"by": "elder", "mood": "worried", "text": "Rats don't pack crates. I should have shown you this before you went."},
			{"by": "elder", "mood": "neutral", "text": "When something comes at you, don't just jump out of the way. Roll through it, and keep your blade out."},
			{"by": "elder", "mood": "happy", "text": "And if you fall, fall rolling. My knees learned that the hard way."},
		]},
		"home": [
			{"by": "Uncle Anvil", "mood": "happy", "text": "Forge is lit. Took me an hour to find the bellows."},
			{"by": "Uncle Anvil", "mood": "neutral", "text": "Here. Take this."},
			{"by": "tompel", "mood": "surprised", "text": "Your hammer?"},
			{"by": "Uncle Anvil", "mood": "neutral", "text": "I've got two more somewhere. If I keep this one I'll put it down in another cage."},
			{"by": "Uncle Anvil", "mood": "happy", "text": "Hold on to it for me. I'll ask for it back when I remember where the others are."},
			{"by": "elder", "mood": "neutral", "text": "Granny, you read. What do you make of these tins?"},
			{"by": "Granny Whiskers", "mood": "neutral", "text": "...These aren't letters. Not ours, and not the humans'."},
			{"by": "tompel", "mood": "surprised", "text": "You can read human?"},
			{"by": "Granny Whiskers", "mood": "neutral", "text": "Their fish come wrapped in newspaper. I've eaten a lot of fish."},
			{"by": "Granny Whiskers", "mood": "determined", "text": "Well. Somebody has to go and find the others, and I'm not waiting around for a boy with a pack."},
			{"by": "elder", "mood": "worried", "text": "Granny..."},
		],
		"gives": ["weapon:hammer"],
		"calls": [{"when": "boss", "over": "boss", "by": "The Rat Baron", "text": "Back to digging! All of you!"}],
		"frees": [{"name": "Uncle Anvil", "coat": "black"}], "bonus": 15,
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
			"Deeper in, the birds stopped.",
			"There were stumps cut flat, and ruts in the mud as wide as a hut.",
			"Then we found the cages.",
		],
		"after": [
			"We finally saw one of them. A giant, standing on two legs, with a whistle in his mouth.",
			"The dogs ran to him whenever he blew it.",
			"Granny Whiskers was in the last cage.",
			{"by": "Granny Whiskers", "mood": "determined", "text": "I'd have got out on my own. I was resting."},
			{"by": "tompel", "mood": "neutral", "text": "Sure."},
			{"by": "Granny Whiskers", "mood": "worried", "text": "He had papers on a board, and he wrote us down. On the same list as the rats."},
		],
		"paper": {"at": Vector2(37.0, 22.0), "name": "The Handler's list", "word": "CATS",
			"found": "A board, with papers on it. He's written us down.",
			"book": "The Handler's list had us on it, between the rats and what to do about them.",
			"reads": "\"'Pest count, block four. Rats: 212. Cats: 31. Action: remove.'\" Granny Whiskers reads it twice. \"We're a line on a list, between the rats and what to do about them.\" She copies one word out on a scrap of cloth: CATS. \"So that's how they write us.\""},
		"send_off": [
			{"by": "jogiboy", "mood": "worried", "text": "Four cats out there. One of them's Granny. She smells cross."},
			{"by": "elder", "mood": "worried", "text": "She went out yesterday, on her own. Stubborn old thing. Bring her back, and anyone else you find."},
		],
		"again": ["The cages stand open, as you left them. Only the Handler is left."],
		"teaches": {"by": "Granny Whiskers", "mutations": ["pounce", "riposte"], "lines": [
			{"by": "Granny Whiskers", "mood": "neutral", "text": "You fight like your grandfather. All tail and no patience."},
			{"by": "Granny Whiskers", "mood": "neutral", "text": "Find the one that matters and land on it. Never mind the rest."},
			{"by": "Granny Whiskers", "mood": "determined", "text": "And when something swings at you, let it miss first. Then be there."},
		]},
		"home": [
			{"by": "jogiboy", "mood": "sad", "text": "I could hear the whistle from here."},
			{"by": "jogiboy", "mood": "sad", "text": "Those dogs. Nobody ever takes them out to play."},
			{"by": "tompel", "mood": "worried", "text": "You all right?"},
			{"by": "jogiboy", "mood": "neutral", "text": "Yes. I'm going to go and dig something up."},
		],
		"calls": [{"when": "boss", "over": "boss", "by": "The Handler", "human": true}],
		"frees": [{"name": "Granny Whiskers", "coat": "gray"}], "bonus": 20,
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
			"We followed the ruts until we heard it: a noise like the whole forest screaming.",
			"Saws. Logs stacked higher than the trees they used to be.",
			"There was a sign over the gate, and Granny Whiskers read it out, slowly.",
			{"by": "Granny Whiskers", "mood": "neutral", "text": "Bright Future Timber. Official partner of the Food Land... Acceleration Agency."},
			{"by": "tompel", "mood": "neutral", "text": "What's a Food Land Acceleration Agency?"},
			{"by": "Granny Whiskers", "mood": "neutral", "text": "No idea."},
			{"by": "tompel", "mood": "determined", "text": "Bright Future. Burnt Future, more like."},
			"It was humans. It had always been humans.",
		],
		"after": [
			"The last saw stopped, and it was very quiet after.",
			{"by": "Granny Whiskers", "mood": "neutral", "text": "'Building a Greener Tomorrow.'"},
			{"by": "tompel", "mood": "sad", "text": "There's ash on everything."},
			"Nobody asked where the ash came from. There wasn't a fire anywhere in the sawpits.",
			"Patch crawled out from under a saw bench, sawdust up to his ears.",
			{"by": "Patch", "mood": "neutral", "text": "Took you long enough. I've been under there since the rains."},
			{"by": "Patch", "mood": "happy", "text": "You know the funny thing? A whole season, and not one of them looked down."},
		],
		"paper": {"at": Vector2(34.0, 4.5), "name": "A site board", "word": "IDLE",
			"found": "A board off their fence. Granny will want this.",
			"book": "Their site board called the forest idle land.",
			"reads": "\"'From Idle Land to Plenty.' Idle.\" Granny Whiskers taps the word. \"That's a forest nobody's selling. That's us, having lunch.\" She copies it out: IDLE."},
		"send_off": [
			{"by": "Granny Whiskers", "mood": "worried", "text": "Follow the ruts. Whatever made those wasn't small."},
		],
		"again": ["The saws are still in pieces. Only the feller buncher is left."],
		"teaches": {"by": "Patch", "mutations": ["ankle_cutter", "caltrops"], "lines": [
			{"by": "Patch", "mood": "neutral", "text": "Their boots are slow to turn. Get in between them and cut."},
			{"by": "Patch", "mood": "neutral", "text": "And leave these behind you. Bent nails. They don't look down, remember."},
		]},
		"home": [
			{"by": "Patch", "mood": "neutral", "text": "Give me a week and the Elder has a roof again."},
			{"by": "elder", "mood": "happy", "text": "Good. I've a lot to write down."},
			{"by": "jogiboy", "mood": "sad", "text": "I've seen giants before. I used to live with them."},
			{"by": "jogiboy", "mood": "sad", "text": "Downriver, where the palm trees are. They kept me at a gate."},
			{"by": "tompel", "mood": "surprised", "text": "The palm trees. I walked right past them."},
			{"by": "jogiboy", "mood": "neutral", "text": "One of them used to take me out to play. These were his keys."},
			{"by": "jogiboy", "mood": "happy", "text": "I kept them. He'd have wanted me to."},
		],
		"frees": [{"name": "Patch", "coat": "cream"}], "bonus": 30,
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
			"This was the old fig grove. From the ridge, you could count the stumps.",
			"We decided to stay there until they made us leave.",
		],
		"after": [
			"The loader's arm was still twitching. Then it stopped.",
			"Somebody dropped out of the last fig tree and landed next to Tompel.",
			{"by": "Saffron", "mood": "happy", "text": "Finally. I've been up that tree for a month."},
			{"by": "tompel", "mood": "surprised", "text": "A month? What did you eat?"},
			{"by": "Saffron", "mood": "sad", "text": "Figs. Don't talk to me about figs."},
			{"by": "Saffron", "mood": "neutral", "text": "I've watched everything from up there. The logs go downhill, to the river."},
			{"by": "Saffron", "mood": "worried", "text": "And at night there are rats. Lines of them, carrying things south."},
			{"by": "tompel", "mood": "neutral", "text": "Rats are rats."},
			{"by": "Saffron", "mood": "neutral", "text": "If you say so."},
		],
		"paper": {"at": Vector2(41.0, 23.0), "name": "A warning sign", "word": "NOT",
			"found": "A sign off a post, in red letters.",
			"book": "A sign in the fig grove forbade fires. They had put it up themselves.",
			"reads": "\"'Danger. Dry peat. Do not light fires.'\" Granny Whiskers frowns at it. \"They put up a sign against fire, in a grove they'd already cut.\" Nobody has an answer for that. She copies out the small word: NOT."},
		"send_off": [
			{"by": "Patch", "mood": "neutral", "text": "The machines came up from the east. Mind the big ones. They don't look down, but they don't need to."},
		],
		"again": ["You held it once. Only the log loader is left."],
		"teaches": {"by": "Saffron", "mutations": ["long_leap", "dust_cloud"], "lines": [
			{"by": "Saffron", "mood": "happy", "text": "Why go around anything? Run, and jump."},
			{"by": "Saffron", "mood": "neutral", "text": "And when you land, kick up the dirt. They can't bite what they can't see."},
		]},
		"home": [
			{"by": "Saffron", "mood": "neutral", "text": "You can see all the way to the river from my tower."},
			{"by": "Saffron", "mood": "worried", "text": "There's always a bit of smoke down south. All year, even when it rains."},
			{"by": "tompel", "mood": "neutral", "text": "Burnt Future."},
			{"by": "Saffron", "mood": "neutral", "text": "Probably."},
		],
		"calls": [
			{"when": "held:3", "at": Vector2(10.5, 4.0), "by": "Saffron, from somewhere", "text": "Left! No, your other left!"},
			{"when": "held:90", "at": Vector2(10.5, 4.0), "by": "Saffron, from somewhere", "text": "Halfway. They really hate it when you don't leave."},
			{"when": "held:170", "at": Vector2(10.5, 4.0), "by": "Saffron, from somewhere", "text": "Something big is coming from the east. Very big."},
		],
		"frees": [{"name": "Saffron", "coat": "orange"}], "bonus": 40,
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
			"They slid the trunks down to the river on a chute of mud.",
			"At the top, stacks of logs were held back by levers.",
			"We wondered what would happen if somebody pulled them.",
		],
		"after": [
			"One truck fewer on the river road. Its driver ran off toward the offices on the hill.",
			"Then the cab door creaked open, and two cats fell out of it, arguing.",
			{"by": "Coffee", "mood": "determined", "text": "I said left."},
			{"by": "Cream", "mood": "determined", "text": "You said 'not right'. That's different."},
			{"by": "tompel", "mood": "surprised", "text": "What were you doing in there?"},
			{"by": "Cream", "mood": "happy", "text": "He kept his lunch in a box. We had a plan."},
			{"by": "Coffee", "mood": "sad", "text": "Then he locked the door and drove off. That wasn't in the plan."},
		],
		"paper": {"at": Vector2(21.0, 30.0), "name": "A delivery note", "word": "HERE",
			"found": "A note from the truck's cab, with a pen on a string.",
			"book": "The trucks took logs down, and brought drainage pipe back for a partner in the south.",
			"reads": "\"'Logs, forty. Return load: drainage pipe, to partner site, south. Sign here.'\" \"Pipe,\" says Granny Whiskers. \"Who drains a forest?\" She copies out the last word: HERE."},
		"send_off": [
			{"by": "Saffron", "mood": "happy", "text": "Downhill to the river. Don't ride a log. I've tried."},
		],
		"again": ["The levers are still pulled. Only the logging truck is left."],
		"teaches": {"by": "Coffee", "mutations": ["more_charges", "slipstream"], "lines": [
			{"by": "Coffee", "mood": "neutral", "text": "Never roll just once. Roll, roll again, then think."},
			{"by": "Cream", "mood": "happy", "text": "And stay right behind me when I run. You'll go faster than you think you can."},
		]},
		"home": [
			{"by": "Cream", "mood": "happy", "text": "We're open! Everything's half price."},
			{"by": "Coffee", "mood": "determined", "text": "It is not half price."},
			{"by": "Cream", "mood": "neutral", "text": "For him it is."},
			{"by": "Coffee", "mood": "sad", "text": "...For him it is."},
		],
		"frees": [{"name": "Coffee", "coat": "black"}, {"name": "Cream", "coat": "cream"}], "bonus": 50,
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
			"Up on the hill were cabins in rows, and lights that hummed all night.",
			"Every wall inside had a map on it, and every map had our forest on it.",
			{"by": "Granny Whiskers", "mood": "neutral", "text": "'Idle land.'"},
			{"by": "tompel", "mood": "surprised", "text": "Idle?"},
			{"by": "Granny Whiskers", "mood": "worried", "text": "That's what it says. All of it. Us too."},
			{"by": "tompel", "mood": "determined", "text": "Then let's turn their lights off."},
		],
		"after": [
			"With the power gone, the cabins were dark, and their papers were just lying about.",
			{"by": "Granny Whiskers", "mood": "neutral", "text": "'The rest of it, next season. For the nation's food.'"},
			{"by": "Granny Whiskers", "mood": "neutral", "text": "And this one: 'Land made ready for planting... by partner.'"},
			{"by": "tompel", "mood": "neutral", "text": "Which partner?"},
			{"by": "Granny Whiskers", "mood": "neutral", "text": "Doesn't say."},
			"Nobody asked again.",
			"In the hallway stood a glass case, and in it, a little wooden tiger with a very silly face.",
			{"by": "Granny Whiskers", "mood": "neutral", "text": "'Local handicraft. Traditional pest deterrent.'"},
			{"by": "tompel", "mood": "determined", "text": "That's from our village. It's coming home."},
			"Auntie Clove had been locked in the canteen. She had opinions about the canteen.",
			{"by": "Auntie Clove", "mood": "determined", "text": "Rice from a packet. Tea from a packet. Even the sambal came out of a packet."},
			{"by": "Auntie Clove", "mood": "worried", "text": "And look at you. When did you last eat anything green?"},
		],
		"paper": {"at": Vector2(38.0, 23.0), "name": "The permit", "word": "LIVE",
			"found": "It was in a frame. It's stamped all over.",
			"book": "The permit said no persons lived on the land.",
			"reads": "\"'Concession thirty-nine. No persons live on the land described.'\" Granny Whiskers puts it down, and picks it up again. \"No persons.\" She copies one word out, very neatly: LIVE."},
		"send_off": [
			{"by": "Cream", "mood": "happy", "text": "The offices are up the hill. I saw them first."},
			{"by": "Coffee", "mood": "determined", "text": "You did not."},
		],
		"again": ["The generators are still dead. Only the bulldozer is left."],
		"teaches": {"by": "Auntie Clove", "mutations": ["lick_your_wounds", "scent_trail"], "lines": [
			{"by": "Auntie Clove", "mood": "neutral", "text": "Tend to your cuts as you go. Don't wait until it's over to fuss."},
			{"by": "Auntie Clove", "mood": "happy", "text": "And carry a pinch of this. Dogs can't resist turmeric. Let them follow that instead of you."},
		]},
		"home": [
			{"by": "Auntie Clove", "mood": "neutral", "text": "Sit. Drink this."},
			{"by": "tompel", "mood": "worried", "text": "What's in it?"},
			{"by": "Auntie Clove", "mood": "neutral", "text": "Drink it."},
			"The little wooden tiger went by the gate, beside the big one.",
			{"by": "jogiboy", "mood": "happy", "text": "They look the same."},
			{"by": "elder", "mood": "happy", "text": "They do, don't they. Somebody downriver must have bought one off our carvers, years ago."},
		],
		"frees": [{"name": "Auntie Clove", "coat": "cream"}], "bonus": 60,
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
			"At the airstrip the ribbon was already up, strung across the runway between two poles.",
			"If the helicopter never got down, there'd be nobody to cut it.",
		],
		"after": [
			"The helicopter came down in the long grass and stayed there.",
			"The man with the scissors ran, and the ribbon never got cut.",
			"The last of them left down the river road, on foot.",
			"Skipper had been tied up in the hangar with the cargo.",
			{"by": "Skipper", "mood": "neutral", "text": "Is that the helicopter?"},
			{"by": "tompel", "mood": "happy", "text": "It was."},
			{"by": "Skipper", "mood": "happy", "text": "Good."},
			"He never saw who did it. A storm, he'll have said. Or rats.",
			"They'll be back one day. Giants are stubborn.",
			"And they still don't know we live here. Granny says she hasn't the words for it yet.",
			"It was a tall order. We aren't done filling it.",
		],
		"paper": {"at": Vector2(8.0, 19.0), "name": "The speech", "word": "",
			"found": "Cards, in a big hand. He dropped them running.",
			"book": "The speech said that where nothing was, there was now a future.",
			"reads": "\"'Today, where nothing was, there is a future.'\" Granny Whiskers reads the rest to herself, and puts the cards on the fire. \"He was going to say that standing on our fig grove.\""},
		"after_written": [
			"The helicopter came down in the long grass and stayed there.",
			"The man with the scissors ran for the ribbon anyway. Then he stopped.",
			"Across the runway, a paw wide, in their own letters: NOT IDLE. CATS LIVE HERE.",
			{"by": "Granny Whiskers", "mood": "determined", "text": "I spelled it twice. I wasn't having them say they couldn't read it."},
			"He read it. We watched him read it. Then, slowly, he looked down.",
			"Tompel was sitting on the end of the ribbon.",
			{"by": "tompel", "mood": "neutral", "text": "Hello."},
			"It was only a meow, to him. It was enough.",
			"He put the scissors in his pocket. The last of them left down the river road, on foot.",
			"Skipper had been tied up in the hangar with the cargo.",
			{"by": "Skipper", "mood": "neutral", "text": "Is that the helicopter?"},
			{"by": "tompel", "mood": "happy", "text": "It was."},
			{"by": "Skipper", "mood": "happy", "text": "Good."},
			"They'll be back one day. Giants are stubborn.",
			"But one of them looked down. They'll have to take us seriously now.",
			"It was a tall order. We filled it.",
		],
		"send_off_written": [
			{"by": "Granny Whiskers", "mood": "determined", "text": "Patch has the paint, and I have the words. Keep them busy until it's dry."},
		],
		"send_off": [
			"The whole village came to the gate.",
			{"by": "elder", "mood": "determined", "text": "Somebody important is flying in to cut a ribbon on our forest. I'd rather he didn't."},
		],
		"again": ["The fuel lines are still cut. Only the helicopter is left."],
		"teaches": {"by": "Skipper", "mutations": ["chain_roll"], "lines": [
			{"by": "Skipper", "mood": "neutral", "text": "Don't stop between rolls. Finish one, start the next."},
			{"by": "Skipper", "mood": "neutral", "text": "That's all. I'm not one for talking."},
		]},
		"home": [
			{"by": "elder", "mood": "happy", "text": "Rest. For once in your life, rest."},
			{"by": "tompel", "mood": "neutral", "text": "I'm resting."},
			{"by": "elder", "mood": "neutral", "text": "You're holding a hammer."},
			{"by": "Uncle Anvil", "mood": "worried", "text": "Have you seen my hammer?"},
			{"by": "tompel", "mood": "neutral", "text": "You gave it to me."},
			{"by": "Uncle Anvil", "mood": "surprised", "text": "...Did I? Well. Keep it, then."},
			{"by": "Cream", "mood": "happy", "text": "Liberation sale! Everything must go!"},
			{"by": "Coffee", "mood": "determined", "text": "We said 'Freedom sale'."},
			{"by": "Patch", "mood": "happy", "text": "Fits, doesn't it? They had boxes of these hard hats."},
			{"by": "Saffron", "mood": "worried", "text": "The company's gone, and there are more rats than ever. Funny, that."},
		],
		"calls": [{"when": "boss", "at": Vector2(31.5, 11.4), "by": "The official, with the scissors", "human": true}],
		"frees": [{"name": "Skipper", "coat": "gray"}], "bonus": 80,
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
			"The edge was burning. Not the trees: the ground, smoking up through the dirt where the mounds had been.",
			"Then the lights came out of the trees, low and orange, and drifted over the huts.",
			"We had always been told the Keepers' lights meant fire.",
			"Where they touched the thatch, it caught.",
			{"by": "elder", "mood": "determined", "text": "Water! From the well, a bucket at a time!"},
			"And something big was watching from the trees.",
		],
		"after": [
			"The Great Tiger lay down in the middle of the square, and the lights went out one by one.",
			"Nobody in the village had ever seen him, but we knew who he was.",
			{"by": "great_tiger", "mood": "sad", "text": "Every time the forest burns, they say it was us."},
			{"by": "great_tiger", "mood": "sad", "text": "We go to the fires to put them out. Every time. And every time, we are blamed."},
			{"by": "great_tiger", "mood": "determined", "text": "Tonight it burned beside your village. And here you are, dressed like the men with the saws."},
			{"by": "Patch", "mood": "surprised", "text": "...Oh."},
			{"by": "elder", "mood": "sad", "text": "We took it all from them. We thought it was ours to take."},
			{"by": "Granny Whiskers", "mood": "sad", "text": "My grandmother blamed you for her knees. I blamed you for the rest. I'm sorry."},
			{"by": "great_tiger", "mood": "neutral", "text": "Your grandmother's knees were bad, little one. That was not us either."},
			"The Elder brought out one of the tins from the edge.",
			{"by": "elder", "mood": "neutral", "text": "This was under the mounds. Right where it's burning now."},
			{"by": "great_tiger", "mood": "determined", "text": "That smell. It is in every burned grove I have walked through."},
			{"by": "jogiboy", "mood": "surprised", "text": "...That's rat."},
			{"by": "tompel", "mood": "surprised", "text": "The rats. Under our feet, the whole time."},
			{"by": "tompel", "mood": "sad", "text": "I said rats were rats. That's what the giants say about us."},
			{"by": "elder", "mood": "sad", "text": "Nests. We thought they were nests."},
			{"by": "Saffron", "mood": "worried", "text": "The lines at night, going south. I told you."},
			{"by": "tompel", "mood": "sad", "text": "So Burnt Future never burned anything."},
			{"by": "Patch", "mood": "neutral", "text": "They cut everything down. That's bad enough."},
			{"by": "great_tiger", "mood": "sad", "text": "The groves that burned are still sick. The Keepers there cannot rest, and cannot think."},
			{"by": "great_tiger", "mood": "determined", "text": "I will set a stone by your gate. Through it is the way to them. Come and help me."},
			"On his way out, the Great Tiger stopped at the gate and looked at the statue for a long time.",
			{"by": "great_tiger", "mood": "surprised", "text": "..."},
			{"by": "jogiboy", "mood": "happy", "text": "See? Same face."},
		],
		"send_off": [
			"We had a few quiet weeks, the first in a long time.",
			"Halfway to the gate, Jogiboy stopped dead, his ears up.",
			{"by": "jogiboy", "mood": "worried", "text": "Smoke. Not out there. Behind us."},
		],
		"again": ["The fires are out. Only the Great Tiger is left."],
		"calls": [
			{"when": "roof", "by": "A Keeper", "text": "Fire-bringers!"},
			{"when": "roof", "by": "A Keeper", "text": "You wear their smell!"},
		],
		"frees": [], "bonus": 100,
	},
]

## Endless, once the forest's spirits are friends: a corrupted grove, a fresh one every run, to be
## cleansed of what the company left. Each grove is one of these, laid out from the run's own
## seed: its look, its size, and what stands in it.
const GROVES: Array[Dictionary] = [
	{
		"id": "sick_grove", "name": "A sick grove", "ground": "deep", "size": Vector2(52.0, 32.0),
		"scatter": [{"kind": "tree", "count": 32, "radius": [0.5, 0.85]}, {"kind": "bush", "count": 16, "radius": [0.5, 0.9]}],
	},
	{
		"id": "burned_peat", "name": "The burned peat", "ground": "peat", "size": Vector2(56.0, 32.0),
		"scatter": [{"kind": "stump", "count": 40, "radius": [0.3, 0.5]}, {"kind": "tree", "count": 8, "radius": [0.45, 0.6]}, {"kind": "rock", "count": 7, "radius": [0.4, 0.7]}],
	},
	{
		"id": "riverbank", "name": "The riverbank", "ground": "riverbank", "size": Vector2(60.0, 28.0),
		"obstacles": [{"kind": "water", "rect": Rect2(0.0, 28.0 - 1.75, 60.0, 1.75)}],
		"scatter": [{"kind": "tree", "count": 13, "radius": [0.45, 0.7]}, {"kind": "bush", "count": 21, "radius": [0.45, 0.8]}, {"kind": "rock", "count": 10, "radius": [0.4, 0.8]}],
	},
]
## What comes at him in a grove: its Keepers, maddened by the smoke; the Free Float's peons, still
## digging, and the tuyul they pay; and Burnt Future's machines, left behind and still working,
## with something else at the controls. The company's traps are still there too, with cats in them.
const GROVE_PLAN := {
	"rats": {"rate": 1.4, "growth": 0.05, "kinds": {"wisp": 5, "tuyul": 1, "pocong": 2, "rat": 2}},
	"packs": [{"kind": "sapling", "from": 40.0, "interval": 35.0, "pack": 4, "most": 12}, {"kind": "monkey", "from": 60.0, "interval": 30.0, "pack": 3, "most": 9}],
	"machines": {"from": 300.0, "interval": 300.0, "kind": "feller_buncher"},
	"cages": {"from": 40.0, "interval": 75.0, "most": 2},
}


## Once the grove is cleansed: the Keepers are gone, and the ones who were paid to be there come
## harder. The Free Float's peons and torchbearers, its foremen, and in time a Baron; the tuyul;
## and Green Promise Plantations' planting crews, come to put oil palm in the ash.
const GROVE_CLEANSED_PLAN := {
	"rats": {"rate": 1.7, "growth": 0.06, "kinds": {"rat": 6, "tuyul": 2, "torchbearer": 2}},
	"packs": [{"kind": "foreman", "from": 25.0, "interval": 40.0, "pack": 1, "most": 3}, {"kind": "rat_baron", "from": 150.0, "interval": 300.0, "pack": 1, "most": 1}],
	"giants": {"from": 60.0, "interval": 40.0, "most": 3, "kind": "planter"},
	"cages": {"from": 40.0, "interval": 75.0, "most": 2},
}
## What's said in a grove, in the fight: the Keepers coming to themselves, Green Promise's crew
## arriving (a human, so only scribbles), and a Baron of the Free Float, demoted to the groves.
const GROVE_CALLS: Array[Dictionary] = [
	{"when": "cleansed", "by": "A Keeper", "text": "...Where are we? Who are you?"},
	{"when": "crew", "by": "Green Promise's foreman", "human": true},
	{"when": "baron", "by": "A Baron of the Free Float", "text": "I've been reclassified! Do you know what that does to a career?"},
]
## Going into a grove, the first time each kind is seen: the book's line for it.
const GROVE_LINES := {
	"sick_grove": "The trees there still remembered the smoke. So did the Keepers.",
	"burned_peat": "The ground was warm under our feet. It shouldn't have been.",
	"riverbank": "The river had carried their logs away for a year. It was in a bad mood.",
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
## The area whose first freeing hands him a thing, by card id, or "".
static func gives(id: String) -> String:
	for area: Dictionary in LIST:
		if id in area.get("gives", []):
			return area.id
	return ""


## What's told as an area is freed: the airstrip's has another ending once the cats can write.
static func after_lines(id: String, written := false) -> Array:
	var area := named(id)
	return area.after_written if written and area.has("after_written") else area.after


## And as he's seen off to it.
static func send_off_lines(id: String, written := false) -> Array:
	var area := named(id)
	var lines: Array = (area.get("send_off", []) as Array).duplicate()
	if written:
		lines.append_array(area.get("send_off_written", []))
	return lines


static func teaches(id: String) -> Array[String]:
	var mutations: Array[String] = []
	mutations.assign(named(id).get("teaches", {}).get("mutations", []))
	return mutations


static func ids() -> Array[String]:
	var all: Array[String] = []
	for area in LIST:
		all.append(area.id)
	return all
