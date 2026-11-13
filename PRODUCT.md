# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

That value is the nearest the schema has, and it's only half true. This record covers two
surfaces, and their constraints never mix:

- **The game's own interface**: a Godot 4.7 desktop game (Windows, macOS, Linux), drawn at 640 by
  360 in pixel art, played with a keyboard or a gamepad. Not a web page; nothing about web
  layout, browsers or responsive design applies to it.
- **Web pages about the game**, such as itrium.id/tall-order. These are web, and none are kept
  in this repository.

## Users

**People who already play auto-shooters**: Vampire Survivors, Megabonk and the like. They play
on a desktop, in runs of 15 to 30 minutes, alone or with up to three friends, and they judge
Tall Order against the games they already know. They read a screen full of enemies at a glance
and have no patience for an interface that makes them stop to work out what it's saying.

Their left hand never leaves movement. Everything they choose, they choose while the fight goes
on.

## Product Purpose

Felterra: Tall Order is an auto-shooter roguelike where a crew of cats fights giants: a human
company clearing their forest, to whom cats are pests. The player steers, dodges and chooses
upgrades; the weapons aim and fire on their own.

Two ways to play: **Liberation**, the story, solo, freeing the forest area by area; and
**Endless**, the score chase, a fresh clearing every run, for one to four players on one screen
or online.

**Success is people playing and coming back**: runs finished, players returning, and bringing
friends. How the game pays for itself is undecided, and isn't the measure for now.

## Positioning

- **Underfoot against giants.** Humans are at real scale, five to six times a cat's height. The
  cats can't out-muscle them; they win at ankle height, and by tricking a giant into flattening
  his own horde.
- **Honest physics.** Everything has a height above the ground. Thrown things arc, bodies fall
  and crush what's under them, logs roll. Nothing is a canned animation standing in for it.
- **Nothing stops for a choice.** Level-up cards are held and played in the fight; they never
  expire and never pause the world, so solo and online play the same and scores compare fairly.
- **Every stat is something you can see on the cat.** Stats come only from gear, and gear shows
  on his body.
- **A place and a point of view.** The Nusantara seas, Indonesian weapons and folklore, and
  satire of deforestation and peat fires where the system is the joke and nobody real is named.
  Warm, cheeky and fierce; never preaching.

## Operating Context

- A run is 15 to 30 minutes; progress carries over between runs, in the village.
- The flow lives in the village, which is walked, not a menu. The title is three choices: Play,
  Settings and Leave.
- Keyboard or gamepad. The mouse is optional: clicking a card works, nothing needs it.
- Cooperative play is one to four, on one screen with a shared camera, or online with a
  six-letter room code. No split screen and no zoom.
- The game is downloaded as a zip from the GitHub releases page. The builds aren't signed yet,
  so Windows and macOS warn on first launch, and the README walks through it.
- Players reach the team on Itrium's Discord or the repository's issues.

## Capabilities and Constraints

**The game's interface**

- 640 by 360, 16-pixel tiles. One pixel is always the same size: nothing is scaled, and there's
  no art at another resolution.
- Every color comes from `game/palette.gd`, about 32 of them. No inline colors.
- All text is Itrium Pixel, a submodule that's never edited here. A missing glyph is added in
  itriumid/pixel-font first.
- Effects are palette pixels, never smooth gradients; only lighting is smooth. A see-through
  panel is a checkerboard of palette pixels, not a blend.
- Card text is short. A card that needs a paragraph means the upgrade is too complicated.
- Online, the pause menu opens over a world that keeps running.
- The full rules are in `docs/design.md` and `AGENTS.md`, which win over this summary.

**Terminology**

- Names on screen are in English; a thing's story gives its Indonesian name once. Words English
  has no equivalent for (golok, mandau, kujang) stay.
- Names take capitals; everything else is lowercase in a sentence and sentence case on a label.
- American spelling.
- The game's words: Liberation, Endless, the village, a run, cards, fireflies (experience),
  salvage, cloth, offerings, Nine Lives, the dodge and its mutations, gear, support.

**Undecided**

- How the game pays for itself. Whatever is chosen is said plainly before it happens, and the
  download stays free.
- Whether it goes to a store. Online play through Steam would be decided then.
- Languages other than English. The ids underneath are kept stable so a translation is a setting
  later.

## Brand Commitments

- **Name:** Felterra: Tall Order. Felterra is the world, shared with other games; Tall Order is
  this one. It's made by Itrium.
- **Voice:** warm, cheeky and fierce, the way cats are. Plain words, said directly. Honest about
  what isn't done or decided.
- **In the game:** Itrium Pixel and the game's own palette.
- **On Itrium's sites:** the Rhodonite palette only, and Plus Jakarta Sans served from the site
  itself. Pink means one thing at a time, text on pink is graphite, and graphite replaces black.
  The rules are in the handbook's `itrium/brand.md`.
- **Free, with no advertisements and nothing that tracks the player.**

## Evidence on Hand

- The running game. `godot --path . -- --screenshot=<path>.png` saves a real frame of any state
  the flags in `AGENTS.md` can set up; `tools/sprite_sheet.gd` lays out every sprite.
- `docs/design.md`, the design and its reasons, and `docs/catalog.md`, everything built or
  planned.
- `icon.png`, drawn from the cat's sprite. There's no `CREDITS.md` yet, so no outside art
  is on record.
- The README's copy on downloads, cost and how the art is made.

**What there isn't, and what nothing may invent:** reviews, testimonials, press, player counts,
awards, a store page, a trailer, or a price.

**What must be said, not hidden:** the pixel art, sound and music are placeholders made with AI
tools, to be replaced by credited artists and musicians once the game earns enough.

## Product Principles

1. **Read at a glance, in a crowd.** The player is being chased while they read. Anything on
   screen has to be understood without stopping.
2. **Shown, not said.** Who's talking, what's worn, what's ailing an enemy and what's new are
   all on the thing itself before they're in a panel.
3. **Never by color alone.** Rarity is a frame shape and pips as well as a color; a new best is
   marked in words.
4. **The player's time is theirs.** No timers on choices, every cutscene can be skipped, and
   "one more run" doesn't mean a walk across the village.
5. **Say it plainly.** What's free, what's a placeholder and what's undecided are stated, in the
   game and about it.

## Accessibility & Inclusion

- **Level AA of the Web Content Accessibility Guidelines** for web pages, per Itrium's
  conventions: 4.5:1 for text on every surface it sits on, 3:1 for focus outlines.
- **In the game**, the parts of level AA that carry over are kept:
  - Every cutscene can be skipped: Escape skips it, Enter hurries a line, and both keys show on
    screen. A setting makes story lines wait for Enter, so nobody reads against a clock.
  - Meaning never rests on color alone.
  - A controller gets the same layout as the keyboard. Rebinding is in the design and not built
    yet.
  - Blood, damage numbers and how many of the fallen stay lying each have a setting.
