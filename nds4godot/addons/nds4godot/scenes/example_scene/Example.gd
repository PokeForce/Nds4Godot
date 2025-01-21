extends Control

###
## An example script for decoding a Full Pokemon Icon (or known as a Battle Sprite) and displaying it within a TextureRect
###

# The TextureRect node to draw to
@onready var sprite: TextureRect = $Sprite

# The Pokedex ID for Mew, a popular Pokemon
const MEW_POKEDEX_ID: int = 151

# Cache for the textures to prevent repeated look-ups for particular sprites
var full_icon_cache: Dictionary = {}

# Build the TextureRect
func _ready() -> void:
	sprite.texture = fetch_full_pokemon_icon(MEW_POKEDEX_ID)

# Fetch and cache a full Pokémon icon with support for back, female, and shiny variations
func fetch_full_pokemon_icon(id: int, back: bool = false, female: bool = false, shiny: bool = false) -> Texture:
	var cache_key: String = "%s_%s_%s_%s" % [str(id), str(back), str(female), str(shiny)]
	
	# Check if the icon is already cached
	if full_icon_cache.has(cache_key):
		return full_icon_cache[cache_key]

	# Set the current NARC for full Pokémon icons
	NDSCompanion.set_current_narc("a/0/0/4")

	# Calculate the sprite and palette indices based on parameters
	var count: int = 20
	var sprite_index: int
	if back:
		if female:
			sprite_index = 10
		else:
			sprite_index = 9
	else:
		if female:
			sprite_index = 1
		else:
			sprite_index = 0

	var palette_index: int
	if shiny:
		palette_index = 19
	else:
		palette_index = 18

	# Retrieve the sprite and palette data
	var sprite_offset: int = (id * count) + sprite_index
	var palette_offset: int = (id * count) + palette_index
	var sprite_data: PackedByteArray = NDSCompanion.current_narc.fimg_entry[sprite_offset].data
	var palette_data: PackedByteArray = NDSCompanion.current_narc.fimg_entry[palette_offset].data

	# If the data is empty, return an empty texture
	if sprite_data.is_empty() or palette_data.is_empty():
		return NDSCompanion.get_empty_texture()

	# Decompress and process the sprite data
	var input_stream: EndianBinaryReader = EndianBinaryReader.new(sprite_data)
	var decompressed_data: PackedByteArray = LZ11.decompress_lz11(input_stream, sprite_data.size())
	var image: Image = BattleSprite.draw_image(palette_data, decompressed_data)

	# Remove the top-left color and crop the image
	var image_bounds: Rect2 = NDSCompanion.remove_top_left_color_and_get_bounds(image)
	var cropped_image: Image = Image.create(image_bounds.size.x, image_bounds.size.y, false, Image.FORMAT_RGBA8)
	cropped_image.blit_rect(image, image_bounds, Vector2(0, 0))
	var image_texture: Texture = ImageTexture.create_from_image(cropped_image)

	# If the generated image is empty, return an empty texture
	if image_texture.get_image().is_empty():
		return NDSCompanion.get_empty_texture()

	# Cache the full icon for future use
	full_icon_cache[cache_key] = image_texture
	return image_texture
