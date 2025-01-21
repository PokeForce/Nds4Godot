# Nds4Godot

[![License: GNU GPL 3.0](https://img.shields.io/github/license/RoadrunnerWMC/ndspy.svg?logo=gnu&logoColor=white)](https://www.gnu.org/licenses/gpl-3.0)

A GDScript conversion of [Nds4j](https://github.com/turtleisaac/Nds4j) that was built to decode Nintendo DS ROM files, open-sourced to comply with GPL-3.0.

This plugin primarily supports the reading of `NARC` file types, and an example [Scene](https://github.com/PokeForce/Nds4Godot/blob/main/nds4godot/addons/nds4godot/scenes/example_scene/Example.tscn), and [Script](https://github.com/PokeForce/Nds4Godot/blob/main/nds4godot/addons/nds4godot/scenes/example_scene/Example.gd) have been provided to show how to utilize the [NdsCompanion](https://github.com/PokeForce/Nds4Godot/blob/main/nds4godot/addons/nds4godot/scripts/NdsCompanion.gd) singleton.

# Starting

To begin, start by specifying the path to your `.nds` ROM in `NdsCompanion`. This is where the plugin will traverse to when grabbing the requested `Narc`:

```gdscript
# Update this path to direct to your `.nds` file
var ROM_PATH: String = "user://roms/bw.nds"
```

**Note: The examples provided in this plugin are using a Generation 5 (Black, White) Pokemon ROM.**

# Example Scene

Once your ROM path has been specified, you can check out the `Example.gd` script, and set a Pokemon you wish to view:

```gdscript
# The Pokedex ID for Mew, a popular Pokemon
const MEW_POKEDEX_ID: int = 151
```

This is used for the `_ready()` function, where the `sprite` `TextureRect` is given the texture from the `fetch_full_pokemon_icon` function.

```gdscript
# Build the TextureRect
func _ready() -> void:
	sprite.texture = fetch_full_pokemon_icon(MEW_POKEDEX_ID)
```

Once you've specified the Pokemon of your choice, simply run the `Example.tscn` scene, and view the sprite!

# Credits

Full credits are given to [turtleisaac](https://github.com/turtleisaac) for the original [Nds4j](https://github.com/turtleisaac/Nds4j) code.

# FAQ

- Nds4Godot has been primarily modified for [PokeForce](https://pokeforce), and is missing a lot of core functionality of the original project.
- We currently do not plan to offer support beyond what the initial plugin offers.
- This plugin was built and tested with [Godot](https://github.com/godotengine/godot) 4.4-beta1
