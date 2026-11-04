class_name JogiboySays
extends RefCounted
## What Jogiboy says about the news in the village, in his own way: simple, and saying exactly what
## he notices. Each moment has plenty of ways of saying it, so it's never the same twice running.
## "{name}" is who has the news (or the place), "{has}", "{wants}", "{was}" and "{is}" agree with
## them.

const BARKS: Array[String] = ["Arf!", "Arf arf!", "This way!", "Over here!", "Come on!"]
const FOR_A_PERSON := {
	"nearing": [
		"{name} {wants} a word with you.",
		"Ooh. {name} {has} something for you.",
		"{name} {was} asking about you.",
		"I think {name} {wants} to talk to you.",
		"Go and see {name}. I'll wait here.",
		"{name} {has} news. I can smell it.",
		"That's {name}. {name} {wants} you, not me.",
	],
	"lingering": [
		"Go on. Say hello.",
		"{name} won't bite. Probably.",
		"Are you going to talk, or just stand there?",
		"I'm not doing the talking for you.",
		"{name} {is} waiting, you know.",
		"You came all this way. Go on.",
	],
	"leaving": [
		"Hey! {name} wanted to talk to you!",
		"Wrong way! {name} {is} back there.",
		"You're just going to leave {name} waiting?",
		"Okay. {name} can wait, I suppose.",
		"Tompel! You forgot {name}!",
		"Fine. I'll tell {name} you were busy.",
	],
}
const FOR_A_PLACE := {
	"nearing": [
		"There's something new at {name}.",
		"Look, {name}. Something's changed.",
		"Ooh. {name}. Have a look.",
		"I sniffed something new at {name}.",
	],
	"lingering": [
		"Go on, have a look.",
		"Well? Aren't you going to look?",
		"It's right there.",
	],
	"leaving": [
		"Hey! You didn't look at {name}!",
		"Wrong way! It's back at {name}.",
		"Okay. {name} will still be there later.",
	],
}


## A bark, the count'th of them.
static func bark(count: int) -> String:
	return BARKS[count % BARKS.size()]


## What he says at a moment ("nearing", "lingering", "leaving") about whoever has the news
## ({name, person, plural}), the count'th thing he's said: a different way each time.
static func line(moment: String, teller: Dictionary, count: int) -> String:
	var ways: Array = (FOR_A_PERSON if teller.get("person", false) else FOR_A_PLACE).get(moment, [])
	if ways.is_empty():
		return ""
	var plural: bool = teller.get("plural", false)
	var said: String = ways[posmod(count + hash(teller.name), ways.size())]
	said = said.replace("{has}", "have" if plural else "has").replace("{wants}", "want" if plural else "wants")
	said = said.replace("{was}", "were" if plural else "was").replace("{is}", "are" if plural else "is")
	said = said.replace("{name}", teller.name)
	# Every sentence starts with a capital: "the Elder" too, when he starts one.
	var capitalized := ""
	var starting := true
	for letter in said:
		capitalized += letter.to_upper() if starting and letter != " " else letter
		if letter != " ":
			starting = letter in [".", "!", "?"]
	return capitalized
