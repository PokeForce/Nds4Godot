extends Node

# Path constants for ROM files
# Update this path to direct to your `.nds` file
var ROM_PATH: String = "user://roms/bw.nds"

# Cache dictionaries for Narc files and sprites
var narc_cache: Dictionary = {}

# Holds the currently loaded NARC file
var current_narc: Narc = null
		
# Sets the current NARC file from the ROM, with optional generation check
func set_current_narc(file_name: String) -> void:
	# Set the path based on the Pokémon generation
	var path: String = ROM_PATH
	# Check if the NARC file is already in the cache
	if narc_cache.has(file_name):
		current_narc = narc_cache[file_name]
	else:
		# Load the ROM and the specified NARC file if not cached
		var rom: ROM = ROM.from_file(path)
		if rom == null:
			print("Failed to load ROM.")
			return
		current_narc = Narc.new(rom.get_file_by_name(file_name))
		# Cache the NARC file for future use
		narc_cache[file_name] = current_narc
		rom.free()
		
# Helper function to return an empty transparent texture
func get_empty_texture() -> Texture:
	var empty_image: Image = Image.new()
	empty_image.create(1, 1, false, Image.FORMAT_RGBA8)
	empty_image.fill(Color(0, 0, 0, 0))
	var empty_texture: ImageTexture = ImageTexture.new()
	empty_texture.create_from_image(empty_image)
	return empty_texture

# Remove the top-left color of an image and return its bounds
func remove_top_left_color_and_get_bounds(image: Image) -> Rect2:
	var top_left_rgb: Color = image.get_pixel(0, 0)
	var min_x: int = image.get_width()
	var min_y: int = image.get_height()
	var max_x: int = 0
	var max_y: int = 0

	# Iterate over the pixels and remove the top-left color
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			if image.get_pixel(x, y) == top_left_rgb:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				if x < min_x:
					min_x = x
				if y < min_y:
					min_y = y
				if x > max_x:
					max_x = x
				if y > max_y:
					max_y = y

	var width: int = max_x - min_x + 1
	var height: int = max_y - min_y + 1
	return Rect2(min_x, min_y, width, height)

# Helper function to remove the top-left color from an image
func remove_top_left_color(image: Image) -> Image:
	var top_left_rgb: Color = image.get_pixel(0, 0)
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			if image.get_pixel(x, y) == top_left_rgb:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	return image
