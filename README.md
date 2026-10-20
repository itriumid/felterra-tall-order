# Felterra: Tall Order

A crew of cats against giants. A human company has bought the forest they live in and moved in
with its machines, and to the humans, cats are pests. We're making them take cats seriously.

An auto-shooter roguelike set in the Nusantara seas of Felterra, a world of cats. Hand-drawn
pixel art, honest physics, and cooperative play for one to four, online or on one screen.

It's at the very beginning: the design is in [`docs/design.md`](docs/design.md), and what runs
so far is a prototype. One cat with a knife or a handgun, level-up cards, a logged clearing, a horde of rats coming out
of the jungle, the light under the canopy, and gear you can try on.

## Controls

| Keyboard | Gamepad | Action |
|---|---|---|
| W A S D or the arrow keys | Left stick | Move |
| Space | A | Dodge |
| 1 or 2 | Left bumper or up | Choose what you start with: knife or handgun |
| T | X | Change how weapons choose a target (also in the settings) |
| B | | Blood on or off (also in the settings) |
| G | Y | Try on gear (until upgrades hand it out) |
| 1, 2, 3 | Bumpers and up | Play a choice from a level-up card |
| R | Down | Reroll the card |
| X with 1, 2 or 3 | B | Banish that choice for the rest of the run |
| Tab (hold) | Back | Read the cards in full |
| Escape | Start | Pause: carry on, settings, start again, leave. It opens on its own when she's down |
| W and S, then Enter or Space | Stick, then A | Choose in the pause menu |
| A and D, or the arrows | Stick | Change a setting: graphics, audio volumes, aim and blood. Settings are kept for next time |
| F3 | | Frame rate and timings |
| F11 | | Full screen |

The cat's weapons choose a target and strike on their own; you move and dodge.

## Built with

[Godot](https://godotengine.org) 4.7, in GDScript, with the Compatibility renderer, for Windows,
macOS and Linux.

## Development

The font, Itrium Pixel, comes from [its own repository](https://github.com/itriumid/pixel-font)
as a git submodule, so clone with `--recurse-submodules`, or run `git submodule update --init`
after cloning.

```sh
# Run the tests (import once first on a fresh checkout)
godot --headless --path . --import
godot --headless --path . --script tests/run_tests.gd

# How long a simulation step takes with a horde of each size
timeout 300 godot --headless --path . --script tools/benchmark_horde.gd
```

## License

The code is free software under the [GNU General Public License, version 3](LICENSE). The name
Felterra and the game's logo aren't covered by that license: forks are welcome, under another
name.
