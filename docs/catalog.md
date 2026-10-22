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
| **Cockroach** | Idea | From the supply crates too: tiny, in swarms, crunched underfoot by her and the giants alike |
| **Survey drone** | Idea | The company's: flies over the clearing and marks her for the giants, who come faster while it sees her |

### Giants

| Name | Status | What it does |
|---|---|---|
| **Worker** | Built | A mini-boss: slow, heavy, stomps (the boot's shadow is the warning). Felled, he topples and crushes what he lands on |
| **Chainsaw worker** | Built | The first elite: revs (the arc on the ground is the warning), then sweeps the saw at shin height, cutting his own horde too |
| **Lantern worker** | Planned | A dropped lantern is a fire |
| **Handler** | Built | The deep forest's boss: keeps his distance, and whistles a pack of dogs in every few seconds |
| **Foreman** | Idea | Stays back with a megaphone; while he shouts, the workers near him hurry |
| **Fumigator** | Idea | Sprays smoke for the pests: it hides what's in it, and makes her cough |
| **Tree climber** | Idea | In spikes and a harness, up a trunk: drops what he cuts on whatever is below |

### Bosses

Machines.

| Name | Status | What it does |
|---|---|---|
| **Rat Baron** | Built | The village's edge: a rat as big as a dog, a bottle cap for a crown, calling rats in around it |
| **Log loader** | Built | The logged clearing: lifts a log overhead and throws it where she stands, its shadow the warning; reaching back to its pile, its grapple's joint is open |
| **Feller buncher** | Built | Grabs and cuts trees in one bite. Crawls on its tracks, crushing the horde while they turn; swings its boom out over her (the head's shadow is the warning), and bites. After a bite the head sits on the ground, its hydraulic joint exposed for double damage; its steel shrugs off most of a hit elsewhere. Five minutes in |
| **Bulldozer** | Built | The company's offices: raises its blade, then rams forward, shoving everything in front of it. Its engine at the back is the weak point: get behind it |
| **Excavator** | Planned | |
| **Logging truck** | Built | The log slide: revs, sounds its horn, then charges down a line; stalled, its fuel tank is open. Wrecked, it tips over |
| **Helicopter** | Built | The airstrip: out of reach in the air, strafing lines marked on the ground; it lands to unload workers, and only then can blades reach it, its tail rotor open |
| **Wood chipper** | Idea | Pulls in what's near its chute, his own horde too; feeding it a giant's lost boot jams it |
| **Skidder** | Idea | Drags logs across the clearing on a chain: a sweeping wall to get out of the way of |

## Areas

Liberation, the story: the forest freed area by area, each one run with a goal and a boss.
Endless is the other mode: a fresh clearing every run, the horde growing until she's down.

| Name | Status | What it holds |
|---|---|---|
| **The village's edge** | Built | Break the nests; the Rat Baron |
| **The deep forest** | Built | Free the caged; the Handler |
| **The sawpits** | Built | Wreck the saws; the feller buncher. The company's sign over the gate |
| **The logged clearing** | Built | Hold the clearing for three minutes; the log loader |
| **The log slide** | Built | Pull the levers and let the logs roll; the logging truck |
| **The company's offices** | Built | Cut the power; the bulldozer |
| **The airstrip** | Built | Cut the fuel lines; the helicopter |
| **Endless** | Built | A fresh clearing every run; co-op lives here |
| **The river** | Idea | Beyond the log slide: the barges that take the wood away |

## Weapons

Held in her paws: two one-handed, or one two-handed. Modern weapons anyone could find, plus what
a country has uniquely, Indonesia first.

### Modern

| Name | Status | What it does |
|---|---|---|
| **Knife** | Built | A starting choice. Close and quick, never runs out. Evolves into the keris |
| **Handgun** | Built | A starting choice. Slow, but it reaches. Evolves into the submachine gun |
| **Submachine gun** | Built | The handgun grown up: fast and loose |
| **Machete** | Built | A broad blade, quick and wide. Evolves into the greatsword |
| **Greatsword** | Built | Two-handed: slow, very wide, very hard, and it throws what it hits |
| **Rifle** | Built | Long, hard-hitting rounds. Evolves into the automatic rifle, or the sniper rifle |
| **Automatic rifle** | Built | The rifle firing fast and loose. Evolves into the assault rifle |
| **Assault rifle** | Built | Two-handed: faster still, and further |
| **Sniper rifle** | Built | Two-handed: slow, very long, and a round goes through four in a line |
| **Shotgun** | Built | Two-handed: seven pellets in a cone, close |
| **Grenade launcher** | Built | Two-handed: lobs a grenade that bursts a meter wide |
| **Lamp oil** | Built | Thrown: the flask breaks where it lands and the oil burns, setting alight whatever stands in it |
| **Nail gun** | Built | Looted from the camp's toolboxes: fast, short, and nails that miss stay where they land, in the next foot on them |
| **Flare gun** | Built | One bright, slow shot that sets what it hits alight |
| **Crossbow** | Built | Two-handed: slow, and a bolt goes through one and into the next |

### Indonesia

| Name | Status | What it does |
|---|---|---|
| **Keris** | Built | The knife grown up: the cats' heritage blade, its wavy edge longer and harder. Evolves into the kerambit |
| **Kerambit** | Built | The curved claw blade: very fast, very close |
| **Golok** | Built | Indonesia's machete: heavier, harder |
| **Celurit** | Built | A sickle: hooks a leg and trips, leaving what it hits down a moment |
| **Rattan staff** | Built | Two-handed: a full sweep around her with heavy knockback |
| **Ketapel** | Built | A slingshot: stones that glance off one into the next, twice |
| **Sumpit** | Built | The Dayak blowpipe: darts that poison and slow |
| **Petasan** | Built | Firecrackers, thrown: they land and pop, four times |
| **Tombak** | Built | Two-handed: the spear, a long thrust in a straight line |
| **Bambu runcing** | Built | Two-handed: the sharpened bamboo spear of the independence fight. It breaks after fourteen hits, and she sharpens a new one |
| **Mandau** | Built | The Dayak sword: heavy, wide swings |
| **Rencong** | Built | The Acehnese dagger: a quick thrust, not a swing |
| **Badik** | Built | The Bugis and Makassar knife: short, deadly up close |
| **Kujang** | Built | The Sundanese blade, its hooked edge pulling what it catches in toward her |
| **Panah** | Built | The bow: arrows lobbed over the horde, each going through one |

## Support

Carried on her back, not in her paws: one drone, and one thing she sets down. She starts with
neither, and each comes with its mount.

| Name | Status | What it does |
|---|---|---|
| **Gun drone** | Built | Drone. Lifts off her pack when something is in reach, hovers off her shoulder and fires down at it; docks again when it's quiet |
| **Net drone** | Built | Drone: lobs nets that pin down what they land on |
| **Meriam bambu** | Built | Set down: the bamboo cannon, as a turret. Strapped across the pack until something is in reach; lobs stones that burst where they land, and after eight shots the tube cracks and she cuts a new one |
| **Mines** | Built | Set down. Ride in pouches on the pack's straps; she drops one every few seconds while enemies are near, up to four, and a foot sets one off, a giant's boot included |
| **Layang-layang** | Built | Drone: a fighting kite circling her, whose glass-coated string cuts what it crosses |
| **Ranjau bambu** | Built | Set down: a bed of bamboo spikes that pricks and slows the horde on it, until it's trampled flat |
| **Radio** | Built | Set down when the horde crowds her: it plays loud, and the horde goes for it instead of her until its battery's flat |

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
| **Bandana** | Built | Neck | Attack speed |
| **Sunglasses** | Built | Eyes | Critical hits |
| **Wristbands** | Built | Paws | Knockback, damage |
| **Sandals** | Built | Feet | Speed |
| **Peci** | Built | Head | Luck, health |
| **Batik shirt** | Built | Body | Health, luck |
| **Raincoat** | Built | Body | Armor |
| **Headlamp** | Built | Eyes | Reach |
| **Rubber boots** | Built | Feet | Armor |
| **Sarong** | Built | Waist | Speed, armor |
| **Tool belt** | Built | Waist | Attack speed |

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
| **Dust cloud** | Idea | Attack | The roll throws up dust that the horde loses her in, for a moment |
| **Scent trail** | Idea | Traps | The roll leaves a scent the horde follows before her |
| **Chain roll** | Idea | Movement | A kill during a roll gives the charge back |

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
| **Critical hits** | Built | A chance for a hit to land twice as hard |
| **Knockback** | Built | Every hit shoves harder |

## Buildings

The village's, every one a ruin at the start. Restoring one takes salvage and rescued cats to
help, and opens what it holds.

| Name | Status | What it opens |
|---|---|---|
| **Smithy** | Built | The smith forges gear and support into the cards, and a forged piece to wear from the start |
| **Huts** | Built | Six, each home to two rescued cats, who weave cloth while she's away. The first is the weaver's, who sells looks |
| **Longhouse** | Built | The elder's: a run can start with any weapon the smith has forged |
| **Map board** | Built | At the gate, never a ruin: the forest carved on a board, where she chooses the next run, an area found so far or Endless |
| **Well** | Idea | Water for the village; a place the cats gather and talk |
| **Watchtower** | Idea | A look over the forest: shows what the next run holds |
| **Healer's hut** | Idea | Jamu brewed between runs |
| **Market** | Idea | Trade salvage for cloth, and back |

## Looks

Bought from the weaver with cloth: looks only, never stats.

| Name | Status | What it is |
|---|---|---|
| **Orange coat** | Built | Her own coat, from the start |
| **Gray coat** | Built | 6 cloth |
| **Black coat** | Built | 8 cloth |
| **Cream coat** | Built | 8 cloth |
| **Festival banners** | Built | The umbul-umbul in red, yellow, cream and teal, from the start |
| **Rhodonite banners** | Built | Pink and graphite. 10 cloth |
| **Lagoon banners** | Built | Teal, cream and blue. 10 cloth |
| **Tabby and spotted coats** | Idea | Patterns over the coats: stripes, spots, a white chest |
| **Scarf colors** | Idea | The red scarf in other colors |
| **Weapon wraps** | Idea | Cloth wound round a weapon's grip, in her colors |
| **House paint** | Idea | Each hut's walls in a color she picks |
| **Lanterns** | Idea | Paper lanterns strung over the path at dusk |

## Ideas

Anything not yet in a section above. Give each a name, the status Idea, and a line on what it
does; when it's decided, move it to its section as Planned.

| Name | Status | What it does |
|---|---|---|
