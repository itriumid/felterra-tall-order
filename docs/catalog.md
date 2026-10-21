# Felterra: Tall Order — catalog

Everything in the game, built or not: enemies, weapons, support, gear, dodge mutations and
stats. It's the one list to brainstorm on, so add to it freely. The rules for how these work
together are in [`design.md`](design.md).

Each row's status is one of:

- **Built:** in the game now. A test checks that these rows match the code exactly, so building
  something means changing its row to Built here, and a Built row always exists in the code.
- **Planned:** decided, in the design, not built yet.
- **Idea:** being considered. Brainstorm here, then promote it to Planned or take it out.

## Enemies

The humans are the first faction, at real scale. Their creatures make up the horde; their
workers are giants.

### The horde

| Name | Status | What it does |
|---|---|---|
| **Rat** | Built | From the supply crates. Small and quick, comes in numbers, bites |
| **Guard dog** | Built | The company's, in a hi-vis harness. Faster than a cat; crouches, then lunges through the air. In packs of three |
| **Gull** | Planned | At the camp |

### Giants

| Name | Status | What it does |
|---|---|---|
| **Worker** | Built | A mini-boss: slow, heavy, stomps (the boot's shadow is the warning). Felled, he topples and crushes what he lands on |
| **Chainsaw worker** | Built | The first elite: revs (the arc on the ground is the warning), then sweeps the saw at shin height, cutting his own horde too |
| **Lantern worker** | Planned | A dropped lantern is a fire |

### Bosses

Machines.

| Name | Status | What it does |
|---|---|---|
| **Feller buncher** | Planned | Grabs and cuts trees in one bite |
| **Bulldozer** | Planned | |
| **Excavator** | Planned | |
| **Logging truck** | Planned | One you can tip over |
| **Helicopter** | Planned | At the end: something giant a cat can't even reach |

## Weapons

Held in her paws: two one-handed, or one two-handed. Modern weapons anyone could find, plus what
a country has uniquely, Indonesia first.

### Modern

| Name | Status | What it does |
|---|---|---|
| **Knife** | Built | A starting choice. Close and quick, never runs out. Evolves into the keris |
| **Handgun** | Built | A starting choice. Slow, but it reaches. Evolves into the submachine gun |
| **Submachine gun** | Built | The handgun grown up: fast and loose |
| **Machete** | Planned | Evolves into the greatsword |
| **Greatsword** | Planned | Two-handed |
| **Rifle** | Planned | Evolves into the automatic rifle, or the sniper rifle |
| **Automatic rifle** | Planned | Heavier, harder-hitting. Evolves into the assault rifle |
| **Assault rifle** | Planned | Two-handed |
| **Sniper rifle** | Planned | Two-handed: slow, long, pierces a line |
| **Shotgun** | Planned | A cone |
| **Grenade launcher** | Planned | |
| **Lamp oil** | Planned | Thrown: sets up fire |

### Indonesia

| Name | Status | What it does |
|---|---|---|
| **Keris** | Built | The knife grown up: the cats' heritage blade, its wavy edge longer and harder. Evolves into the kerambit |
| **Kerambit** | Built | The curved claw blade: very fast, very close |
| **Golok** | Planned | Indonesia's machete, with its own shape and feel |
| **Celurit** | Planned | A sickle: hooks a leg and trips |
| **Rattan staff** | Planned | Heavy knockback |
| **Ketapel** | Planned | A slingshot: stones that ricochet |
| **Sumpit** | Planned | The Dayak blowpipe: darts that poison and slow |
| **Petasan** | Planned | Firecrackers |

## Support

Carried on her back, not in her paws: one drone, and one thing she sets down. She starts with
neither, and each comes with its mount.

| Name | Status | What it does |
|---|---|---|
| **Gun drone** | Planned | Drone. Docks in a cradle on top of the pack when there's nothing to shoot |
| **Net drone** | Planned | Drone |
| **Meriam bambu** | Planned | Set down: the bamboo cannon, as a turret. Strapped across the pack until she sets it down |
| **Mines** | Planned | Set down. Ride in pouches on the pack's straps |

## Gear

Worn and visible, one item to a slot. Stats come only from gear. What's listed is what a common
level gives.

| Name | Status | Slot | Gives |
|---|---|---|---|
| **Caping** | Built | Head | Regeneration, luck |
| **Hard hat** | Built | Head | Armor, health. Looted from the giants |
| **Vest** | Built | Body | Armor, health |
| **Bell collar** | Built | Neck | Luck |
| **Red scarf** | Built | Neck | Speed |
| **Goggles** | Built | Eyes | Reach |
| **Gloves** | Built | Paws | Damage, attack speed |
| **Boots** | Built | Feet | Speed, armor |
| **Jamu flask** | Built | Waist | Adrenaline |

## Dodge mutations

Up to three a run, each changing what the dodge does. Another card for one she has strengthens
it. What the dodge deals grows with damage from her gear, the same as her weapons.

| Name | Status | Kind | What it does |
|---|---|---|---|
| **Rolling slash** | Built | Attack | The roll cuts every creature it touches, once, harder the faster she rolls |
| **Pounce** | Built | Attack | As the roll ends, she leaps onto the nearest enemy within 3 meters, led to where it will be; landing hits what's under her |
| **Ankle cutter** | Built | Attack | Rolling between a giant's legs cuts 12 percent of his full health, once a roll |
| **Land on your feet** | Built | Survival | Knocked off her feet, she rolls out of it, for free |
| **Lick your wounds** | Planned | Survival | Rolling heals a little, capped each minute |
| **Shake it off** | Planned | Survival | Rolling puts out fire and sheds oil. Waits on fire and oil |
| **More charges** | Built | Movement | Another charge for each card; a rarer card brings them back faster |
| **Long leap** | Built | Movement | The roll leaves the ground, high enough to clear a rat and the chainsaw's sweep |
| **Riposte** | Built | Timing | A hit that lands while she's safe in a roll is answered at once, against everything within 0.9 meters |
| **Powder trail** | Planned | Traps | A trail that the first spark ignites, anyone's spark. Waits on fire |
| **Caltrops** | Planned | Traps | |
| **Oil slick** | Planned | Traps | Waits on oil |
| **Rescue roll** | Planned | Crew | Rolling through a downed crewmate revives them faster. Waits on downed crewmates |
| **Slipstream** | Planned | Crew | Rolling past a crewmate speeds them up |

## Stats

What gear gives. A card shows the short form; holding Tab explains each one.

| Name | Status | Does |
|---|---|---|
| **Health** | Built | How much she can take before she's down |
| **Armor** | Built | Each hit takes this much less |
| **Regeneration** | Built | Health that comes back on its own, every second |
| **Adrenaline** | Built | A share of the damage she deals comes back to her as health. Grounded, not magic: it's what other games call lifesteal, and the game explains it |
| **Damage** | Built | Every weapon she holds hits harder |
| **Attack speed** | Built | Every weapon fires and swings sooner |
| **Reach** | Built | Guns reach further, blades reach longer |
| **Speed** | Built | She runs faster |
| **Luck** | Built | Rarer cards turn up more often |

## Ideas

Anything not yet in a section above. Give each a name, the status Idea, and a line on what it
does; when it's decided, move it to its section as Planned.

| Name | Status | What it does |
|---|---|---|
