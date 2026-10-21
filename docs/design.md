# Felterra: Tall Order — design

What we've decided, and why. When the game and this document disagree, one of them is wrong:
fix whichever it is, in the same pull request.

## The game in one line

An auto-shooter roguelike where a crew of cats fights giants: a human company that has bought
their forest and moved in with its machines, and doesn't see cats as people at all.

## World and story

**Felterra** is a world of cats, set in the Nusantara seas. It's shared with other Felterra
games, but this story stands on its own: nothing here depends on another game's events.

The present day. Cats are a modern people, with their own technology at cat scale. Humans exist
too, and to humans, cats are animals: pests, if anything. A human company buys the forest a
community of cats lives in, and moves in to clear it.

The cats can't out-muscle a giant. What they can do is be **underfoot**: in the way, beneath
notice, at ankle height where a giant can't easily reach. The fight is to make the giants take
cats seriously. Stopping them is a tall order.

**Tone:** warm, cheeky and fierce, the way cats are. The game is aware of real-world logging
and land clearing without preaching about it. The humans are a company with a schedule, not
cartoon villains.

**No magic for the cats.** Everything they fight with could be built. Folklore spirits are kept
in reserve as a possible later enemy faction, where being the first supernatural thing in the
game is the point.

## Factions

Many factions over time; **humans are the first**.

Humans are at **real scale**, about five to six times a cat's height. That sets the whole
faction's shape (each enemy, built and planned, is in [`catalog.md`](catalog.md)):

| Role | Who |
|---|---|
| **The horde** | The humans' creatures: rats from the supply crates, guard dogs, gulls at the camp |
| **Mini-bosses** | Human workers: each one a giant, slow, hitting hard. A stomp is a shockwave; a dropped lantern is a fire |
| **Elites** | The chainsaw crew |
| **Bosses** | Machines: a feller buncher (it grabs and cuts trees in one bite), a bulldozer, an excavator, a logging truck you can tip over, and a helicopter at the end: something giant a cat can't even reach |

A felled human is a large body that falls and **crushes what's under it**, his own dogs
included. Tricking a giant into flattening his own horde is a real tactic.

**Guard dogs** are the company's own, in its hi-vis harness: real-sized, taller than an upright
cat and twice as long, and faster than she is, so a dog can't simply be outrun. They come in
packs of three from about a minute in. A dog that gets close crouches (the warning), then
lunges: a real leap through the air that bites if it reaches her, and that a dodge gets her out
from under; it lands, and needs a moment before it runs again. A dog is heavier than a rat, so a
round shoves it less.

The **chainsaw worker** is the first elite: a giant in ear defenders, tougher and slower than a
worker, from two minutes in (every other giant after that). Instead of stomping, he revs the saw
for a little over half a second, its arc marked on the ground in hi-vis (the warning), then
sweeps it at shin height across the ground in front of him. Whatever is in the arc is cut,
his own rats and dogs included, so luring the horde into it is a tactic; a dodge gets her
through it, a long leap clears it, and behind him is safe.

The **feller buncher** is the first boss, five minutes in, and another every five minutes after,
one at a time. It's a tracked machine with a long boom, whose head grabs a tree and saws it
through in one bite. It crawls toward her, turning on the spot before it drives, and whatever is
under its tracks while they turn is crushed, its own horde included; standing still, its steel
just doesn't give. Within reach, it swings its boom out over her, the head's shadow growing on
the ground (the warning), then the head drops and its jaws shut on whatever is there. After a
bite the head sits on the ground for a moment, its hydraulic joint exposed, and hits there do
double; anywhere else, the steel shrugs off most of a hit. That's the fight: dodge the bite, then
punish the joint. Too close for its boom, it backs off. Broken, its engine dies, the boom comes
down, and it stays where it stopped, a wreck to fight around.

## The first map

A clearing the company has cut in an Indonesian tropical forest.

- **The ground is open.** The company has cleared it, which is why there's nothing to block
  movement, and why they're there at all. Mud, burnt earth and log skids vary it: they slow you,
  they never stop you.
- **The jungle is the wall** around the arena: living, thick, impassable.
- **The canopy hangs overhead**, drawn above everything, with no collision. It's above your
  head, so that's honest, and it gives the forest its depth.
- **Low growth never blocks**: grass, ferns, leaf litter. It bends and scatters as things move
  through it.
- **Felled logs are physics objects**, not obstacles: a log rolling down a slope crushes the
  horde.

## The cat

- **Moves freely**, in any direction.
- **Fires automatically.** You steer, dodge and choose upgrades; your weapons aim and shoot.
- **Gear shows on the body.** Every piece of armor and every weapon from an upgrade is visible.

### Starting out

A run starts with a choice of one weapon, and nothing else: armor and accessories are upgrades.

- **Knife**, for close work: quick, and it never runs out.
- **Handgun**, for range: slow, but it reaches.

### Aim

Weapons aim and fire on their own. Each cat picks how they choose a target, and can change it
in a run:

| Mode | Goes for |
|---|---|
| **Nearest** | The closest enemy |
| **Toughest** | The most health left (and, once enemies have armor, defense) |
| **Crowd** | The thickest cluster: best for spread and explosives |

Melee weapons swing a blade through an arc and hit what the blade passes through, at the height
it passes. A swing alternates forehand and backhand.

### Arsenal

Modern weapons anyone could find, plus what a country has uniquely. Indonesia comes first;
other countries' weapons join later, each with its own shape and feel. Everything is something
that could be built.

Every weapon, built and planned, is in [`catalog.md`](catalog.md).

### The dodge

A short roll, with a moment where hits don't land. It takes a charge, which comes back in a
little under a second. Over a run it takes up to **three mutations**, each changing what the
dodge *does*, not just its numbers. Upgrading a mutation you already have strengthens it without
taking another slot, and, as everywhere, a card's rarity changes only how much it gives.

Every mutation, built and planned, is in [`catalog.md`](catalog.md). Some wait on what they act
on: fire and oil, or crewmates who can be downed.

## Runs

- **The flow:** the title (the clearing, with the horde ambling about and now and then a giant)
  offers Play, Settings and Leave. Play goes to the choice of knife or handgun, then the run.
  When she's down, a summary of the run (time survived, level reached, kills, giants felled)
  marks any new best in words as well as color, and offers Go again, Back to the title, or
  Leave. The best run is kept beside the settings.
- A run lasts **15 to 30 minutes**. Progress carries over between runs.
- **Endless mode**: the giants never stop coming; factions arrive and start to mix.
- **The hub is the cats' village** at the forest's edge. It grows between runs: rescued cats
  join, the smith forges better gear. That growth is the progress that carries over, and it's
  the story moving forward.
- Maps push deeper into the camp: the clearings, the sawpits, the log slide to the river, the
  company's offices, the airstrip.

## Upgrades

Level-ups arrive as **cards**. A card offers a choice of three; you hold it until you play it.

- **Cards never expire.** The only pressure is the danger around you, never a timer.
- **Solo and online behave the same.** Nothing pauses for a level-up, so the game is tuned once
  and endless scores compare fairly.
- **A pause menu exists in both.** Solo, it stops the world. Online, it opens over a world that
  keeps running, and its panel is see-through so you can see what's coming.
- Held cards can be read in the pause menu, and are only played in action.
- **The pause menu**: carry on, settings, start again, leave the game. **Settings**: graphics
  (full screen, window size, vertical sync), audio (overall, music, effects and interface
  volumes, each its own bus) and gameplay (aim mode, blood), kept for next time. It opens
  on its own when a run ends, ready to start again. Its see-through panel is a checkerboard of
  palette pixels, not a blend.
- **Card text is short.** If a card needs a paragraph, the upgrade is too complicated.

### What a card can offer

| Kind | Offers |
|---|---|
| **A weapon** | A new one, into a free paw or support slot |
| **A weapon's level** | Levels 1 to 10 for a weapon held; at 10 it can evolve along its family (knife to keris to kerambit, machete to greatsword, handgun to submachine gun, rifle to automatic rifle to assault rifle, or rifle to sniper rifle), keeping everything its levels gave it |
| **Mastery** | Past the top: a weapon at the last of its family, or gear at level 5, takes mastery levels without limit, each worth half a level. A long run keeps growing, which is what makes a god run possible, and a card is never empty |
| **Gear** | Armor and accessories, worn and visible |
| **A dodge mutation** | See the dodge |

**Stats come only from what she wears**, never as cards of their own: every stat she has is
something you can see on her. Each slot holds one item, and the same item's card again levels
it up, to level 5, then into mastery.

The gear for each slot (head, body, neck, eyes, paws, feet and waist) is in
[`catalog.md`](catalog.md).

The stats, and what each means, are in [`catalog.md`](catalog.md) too. A card shows a stat's
short form; holding Tab explains each one, and a card with a stat most players won't know is
marked as worth reading. Adrenaline is what other games call lifesteal: grounded, not magic, and
the game explains it.

### Rarity

Four tiers: **common, uncommon, rare, legendary**, rarer ones turning up less often, and luck
raising the odds.

- **Rarity changes only how much an upgrade gives**, never what it does. A rare "attack
  speed" is a bigger common one.
- **Rarity shows by more than color**: the card's frame shape and its pips change too, so it
  reads as fast for colorblind players.

### What a cat can carry

- **Two paws.** Two one-handed weapons (knife and handgun, keris and golok), or one two-handed
  weapon (rifle, assault rifle, sniper rifle, greatsword) that hits harder and takes both.
- **Two support slots** for what isn't held, one of each kind, both on her back: **one drone**
  and **one thing she sets down** (a turret, or mines). One of each, because two drones or two
  turrets on one pack would never sit right. **She starts with neither.** The drone docks in a
  cradle on top of the pack when there's nothing to shoot; the meriam bambu is a bamboo tube
  strapped across it until she sets it down; mines ride in pouches on the straps. Each comes
  with its mount, and the pack shows from every side.
- **Support works on its own,** as her weapons do, and takes levels the same way. The drone lifts
  off when something comes in reach, hovers off her shoulder and fires down, and docks when it's
  quiet. The cannon is set down where she stands when something comes in reach, and stays there:
  stones lobbed over the horde burst where they land. A bamboo tube cracks after eight shots and
  she cuts a new one, so there's nothing to go back for. Mines are dropped while enemies are near,
  four down at most, and the first foot on one sets it off, a giant's boot included; they never
  hurt the crew.

### Controls

Your left hand never leaves movement.

| Key | Action |
|---|---|
| W A S D | Move |
| Space | Dodge |
| 1, 2, 3 | Pick from the oldest offer you're holding |
| Tab (hold) | Read held offers in full, without stopping anything |
| R | Reroll the offer, if you have rerolls |
| X with 1, 2 or 3 | Banish that choice for the rest of the run |
| Enter | Go again, once a run has ended |
| Escape | Pause menu |

Held offers sit as a strip of icons at the bottom of the screen, with a count. Everything can
be rebound; controllers get the same layout on face buttons and bumpers. The mouse is optional:
clicking a card works, but nothing needs it.

## Playing together

One to four players, **online and on one screen**.

- **Shared experience, separate choices.** The crew levels up together from one pool; each cat
  picks their own upgrade. No kill-stealing, no one falling behind.
- **Nine Lives, shared.** The crew carries nine lives between them. A downed cat is revived by a
  crewmate standing by them for a few seconds; if nobody comes in time, a life is spent and they
  respawn. When the ninth is gone, the run ends.
- **Builds combine across players.** Some upgrades set up what another player's finish: one cat
  spills oil, another throws sparks. Synergy comes from talking, not from one player's build.
- **Scaling** is less than linear: four players face about two and a half times the enemies,
  not four times.
- **Camera:** online, each player has their own, kept within a shared arena. On one screen, a
  shared camera zooms out to fit everyone, up to a leash. No split screen: it halves the
  readability the genre lives on.
- **No friendly fire, but the physics is shared.** A crewmate's explosion doesn't hurt you; it
  still throws you.

**In-game names** carry Indonesian words where they can mean something without having to sell
the game: cooperative play could be *Gotong Royong*, communal work; endless mode could be
*Tanah Air*, holding the homeland.

### Networking

**The host runs the world; each player predicts their own cat.** The host simulates every
enemy and sends compressed positions about 20 times a second; each player's own movement runs
locally so it feels immediate.

Not lockstep: lockstep needs every machine to compute identical results, and GDScript can't
promise identical floating-point math across Windows, macOS and Linux. Online play through
Steam would mean adding GodotSteam later, which is a new dependency and gets decided then.

## Art

**Hand-drawn pixel art**, in the spirit of Stardew Valley and Core Keeper, at 16-pixel tiles on
a 640 by 360 screen. A cat is about 16 to 20 pixels tall, a human about 100.

### Style rules

These apply to everything, wherever it comes from:

1. **One palette**, about 32 colors, in `game/palette.gd`: jungle greens, earth, fur, steel, and
   hi-vis orange for the human workers, which is realistic and makes enemies easy to read in a
   crowd.
2. **One pixel size.** A pixel always covers the same size in the world. Nothing is scaled or
   mixed with art drawn at another resolution.
3. **One light**, from the top left, with three tones per material: light, base and shadow.
4. **Outlines** in a dark warm brown, not black, on characters and anything you can hit or pick
   up. **The environment has none**, which is what makes characters stand out from the ground.
5. **Effects are pixels too**: smoke, sparks and debris are palette particles, never smooth
   gradients. Only lighting is smooth.
6. **Rotations are drawn.** Weapons that aim have hand-drawn angles (8 or 16); rotating pixel
   art in code mangles it.

### Layers

Gear is drawn in layers over the body, Stardew-style, and the cost decides how much gear of
each kind we make:

| Gear | Cost | How |
|---|---|---|
| Weapons | Cheap | One drawing per angle, held at a hand point marked on each body frame |
| Helmets and hats | Cheap | One drawing per direction, moved by a head point per frame |
| Body armor | Expensive | Full frames for every body frame; few designs, with color swaps for variety |
| Trinkets | Cheap | Small sprites at an anchor point |

Hand-drawn frames give the beauty; the simulation gives the motion on top: tail and cloth
follow procedurally, hits and recoil push the sprite, a felled body falls as physics parts.

**Blood** is honest: droplets are particles that arc, fall and stain the ground where they
land; stains dry darker and in time are gone. A setting turns it off, and the same hits throw up
dust and fur instead, so a hit still reads. The fallen lie where they fall, up to a few hundred;
past that the oldest crumble away pixel by pixel rather than vanishing.

**Walking** steps with the ground covered, never a clock, so feet don't slide and a body
thrown through the air doesn't run.

**Light** carries much of the look: sun shafts through the canopy, muzzle flashes on the
ground, torches at dusk. Godot's 2D lights with normal maps should do it; how much of that the
Compatibility renderer supports is the first thing the prototype checks.

### Where the art comes from

For now, we draw it. Free packs are used only when they pass the style rules and are CC0 or
CC-BY, since the repository is public; most won't, and get redrawn. When the game earns money,
the first spend is a commissioned style kit (the cat's body frames, one human, one horde
creature, one tile set) to set the standard everything else is matched to.

### Type

Our own pixel font from Nine Seas for everything you read: capitals 7 pixels tall, proportional,
on whole pixels. A larger display face drawn the same way for titles, card names and banners,
and outlined digits for damage numbers. Outside the game (store page, logo, trailer), Plus
Jakarta Sans.

## Sound

**Every effect is synthesized in code**, like the art is drawn in it: a few shared building
blocks (a tone that sweeps, filtered noise, a pulse wave, the stepped noise of old sound chips),
so every sound belongs to the same game, and there's nothing to license.

- **The simulation drives it.** A shot plays for each round fired; a blade whooshes with each
  swing, deeper for a keris, quicker for a kerambit; a rat's hit is a small high thud and its fall
  a squeak, a giant's hit is deep; a giant's footfalls land with his stride, his stomp booms and
  his fall thunders.
- **Sounds sit where they happen** and fade with distance from the view; the interface's play
  flat, on their own bus.
- **Voices are limited per sound**, so a horde never drowns the rest.
- Each sound comes in a few variants, played a little off pitch, so repeats never ring the same.

**Music**, as a direction (it's still to be composed): chiptune and bitpop in the spirit of
Megabonk's soundtrack, fast (about 150 to 165 beats a minute), in a major key, bright and a
little comical, with **gamelan bronze answering the chiptune lead** between its phrases, the
kentongan tapping the off-beats and kendang fills closing them. It adapts: the main theme
carries the run, and **when a giant walks in, a rock layer joins** (a backbeat and a
power-chord riff), so a giant is heard arriving before he's seen.

Until it's composed, a **placeholder in the same shape** plays: six layers synthesized in code,
all the same eight-bar loop so they stay in step (drums with the kentongan and kendang, the
octave bass, chords that turn to angklung, the chiptune lead, the gamelan answer, and the rock
layer). Drums, bass and the gamelan always play; the chords, then the lead, come in as the horde
thickens around her; the rock layer whenever a giant is on his feet; and everything drops back
in the pause menu. Real music replaces the layers one for one.

## First prototype

Placeholder art; it tests the three biggest risks, all technical:

1. **Light** in the Compatibility renderer: does the canopy-and-muzzle-flash look work?
2. **Layered sprites** with anchor points: a cat whose gear can be swapped.
3. **A horde of a few hundred**, with the height coordinate and physics, to measure what
   GDScript can carry.
