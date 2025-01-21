class_name BTX

# Variables to store texture and palette data sizes and offsets
var size: int = 0
var tex_size: int = 0
var tex_data_size: int = 0
var tex_data_offset: int = 0
var comp_tex_data_size: int = 0
var comp_tex_data_offset: int = 0
var comp_tex_info_data_offset: int = 0
var pal_data_size: int = 0
var pal_info_offset: int = 0
var pal_data_offset: int = 0
var num_objects_3d: int = 0
var size_3d: int = 0
var info_data_size_3d: int = 0
var num_objects_pal: int = 0
var size_pal: int = 0
var info_data_size_pal: int = 0

# Arrays for storing reserved bytes, names, textures, and palettes
var reserved1: PackedByteArray = PackedByteArray()
var reserved2: PackedByteArray = PackedByteArray()
var pal_names: Array[String] = []
var tex_names: Array[String] = []
var textures: Array[TextureData] = []
var palettes: Array[Palette] = []

# Bits-per-pixel format array
var bpp: Array[int] = [0, 8, 2, 4, 8, 2, 8, 16]

# Array to store images
var img: Array[Image] = []

# Initialize BTX object with file system data
func _init(fs: FileImageEntry, shiny: bool = false) -> void:
	var inp: EndianBinaryReader = EndianBinaryReader.new(fs.data)
	if inp.read_int32() != 811095106:
		print("Invalid file format")
		return
	
	# Parse data sizes, offsets, and number of objects
	inp.skip(4)
	size = inp.read_int32()
	inp.skip(12)
	tex_size = inp.read_int32()
	inp.skip(4)
	tex_data_size = inp.read_int16() << 3
	inp.skip(6)
	tex_data_offset = inp.read_int32()
	inp.skip(4)
	comp_tex_data_size = inp.read_int16() << 3
	inp.skip(6)
	comp_tex_data_offset = inp.read_int32()
	comp_tex_info_data_offset = inp.read_int32()
	inp.skip(4)
	pal_data_size = inp.read_int32() << 3
	pal_info_offset = inp.read_int32()
	pal_data_offset = inp.read_int32()
	inp.skip(1)
	num_objects_3d = inp.read_int8()
	img.resize(num_objects_3d)
	size_3d = inp.read_int16()
	reserved1 = inp.read_bytes(10 + 4 * num_objects_3d)
	info_data_size_3d = inp.read_int16()
	
	# Load texture data for each object
	for i in range(num_objects_3d):
		var tmp: TextureData = TextureData.new()
		tmp.offset = inp.read_int16() << 3
		tmp.parameter = inp.read_int16()
		tmp.width_2 = inp.read_int8()
		tmp.unknown_1 = inp.read_int8()
		tmp.height_2 = inp.read_int8()
		tmp.unknown_2 = inp.read_int8()
		tmp.coord_transf = tmp.parameter & 0xE
		tmp.color0 = tmp.parameter >> 13 & 1
		tmp.format = tmp.parameter >> 10 & 7
		tmp.height = 8 << (tmp.parameter >> 7 & 7)
		tmp.width = 8 << (tmp.parameter >> 4 & 7)
		tmp.flip_y = tmp.parameter >> 3 & 1
		tmp.flip_x = tmp.parameter >> 2 & 1
		tmp.repeat_y = tmp.parameter >> 1 & 1
		tmp.repeat_x = tmp.parameter & 1
		tmp.depth = bpp[tmp.format]

		# Default width and height adjustment
		if tmp.width == 0:
			tmp.width = 512 if tmp.unknown_1 & 3 == 2 else 256
		if tmp.height == 0:
			tmp.height = 512 if tmp.height_2 >> 3 & 3 == 2 else 256

		# Read image data
		var img_size: int = tmp.width * tmp.height * tmp.depth / 8
		var curpos: int = inp.get_position()
		if tmp.format != 5:
			inp.seek(tmp.offset + 20 + tex_data_offset)
		else:
			inp.seek(20 + comp_tex_data_offset + tmp.offset)
		tmp.image = inp.read_bytes(img_size)
		inp.seek(curpos)

		# Read special data if format is 5
		if tmp.format == 5:
			var curpos2: int = inp.get_position()
			inp.seek(20 + comp_tex_info_data_offset + tmp.offset / 2)
			tmp.sp_data = inp.read_bytes(img_size / 2)
			inp.seek(curpos)
		
		textures.append(tmp)

	# Load texture and palette names
	for i in range(num_objects_3d):
		var name: String = inp.read_string(16)
		tex_names.append(name)
	inp.skip(1)
	num_objects_pal = inp.read_int8()
	size_pal = inp.read_int16()
	reserved2 = inp.read_bytes(10 + 4 * num_objects_pal)
	info_data_size_pal = inp.read_int16()

	# Load palette data
	for i in range(num_objects_pal):
		var tmp: Palette = Palette.new()
		tmp.offset = inp.read_int16() << 3
		tmp.color0 = inp.read_int16()
		var curpos: int = inp.get_position()
		inp.seek(20 + pal_data_offset + tmp.offset)
		tmp.pal = Palette.to_bgr555_array(inp.read_bytes(pal_data_size - tmp.offset))
		palettes.append(tmp)
		inp.seek(curpos)

	# Load palette names
	for i in range(num_objects_pal):
		var name: String = inp.read_string(16)
		var null_char_index: int = name.find("U+FFFD")
		if null_char_index != -1:
			name = name.erase(0, null_char_index)
		pal_names.append(name)

	# Prepare images
	for i in range(num_objects_3d):
		img[i] = get_image(i, 0, shiny)

# Function to create sprite sheet from images
func create_sprite_sheet(pal_num: int, shiny: bool = false, width: int = 2, height: int = 4) -> Image:
	var first_frame: Image = get_image(0, 0, shiny)
	
	# Check if the first frame's dimensions are valid
	var frame_width: int = first_frame.get_width()
	var frame_height: int = first_frame.get_height()
	
	if frame_width == 0 or frame_height == 0:
		print("Invalid frame size. Width or height is zero.")
		return get_empty_image()

	var image: Image = Image.create(frame_width * width, frame_height * height, false, Image.FORMAT_RGBA8)
	var n: int = 0

	for y: int in range(0, height * frame_height, frame_height):
		for x: int in range(0, width * frame_width, frame_width):
			var current_image: Image = get_image(n, pal_num, shiny)
			image.blit_rect(current_image, Rect2i(0, 0, frame_width, frame_height), Vector2i(x, y))
			n += 1

	return image


func get_image(index: int, pal_num: int, shiny: bool = false) -> Image:
	# Fail-safe: Reset the index to 0 if it's out of bounds
	if textures.size() == 0:
		print("Textures array is empty.")
		return get_empty_image()

	if index < 0 or index >= textures.size():
		print("Index out of bounds, resetting to 0: ", index)
		index = 0

	# Proceed with fetching the texture
	var texture: TextureData = textures[index]
	var width: int = texture.width
	var height: int = texture.height
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var pixel_num: int = width * height
	var palette: Palette = palettes[pal_num + (1 if shiny else 0)]
	var image_data: PackedByteArray = texture.image

	# Handle different texture formats
	match texture.format:
		1:
			for j in range(pixel_num):
				var index_2: int = image_data[j] & 0x1F
				var alpha: float = (image_data[j] >> 5) / 7.0
				var x: int = j % width
				var y: int = j / width
				var color: Color = palette.get_pal_rgbs()[index_2]
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
		2:
			for j in range(pixel_num):
				var byte_index: int = j / 4
				var bit_offset: int = (j % 4) * 2
				var index_2: int = (image_data[byte_index] >> bit_offset) & 0x3
				var x: int = j % width
				var y: int = j / width
				var color: Color = palette.get_pal_rgbs()[index_2]
				image.set_pixel(x, y, color)
		3:
			for j in range(pixel_num):
				var byte_index: int = j / 2
				var bit_offset: int = (j % 2) * 4
				var index_2: int = (image_data[byte_index] >> bit_offset) & 0xF
				var x: int = j % width
				var y: int = j / width
				var color: Color = palette.get_pal_rgbs()[index_2]
				image.set_pixel(x, y, color)
		4:
			for j in range(pixel_num):
				var index_2: int = image_data[j]
				var x: int = j % width
				var y: int = j / width
				var color: Color = palette.get_pal_rgbs()[index_2]
				image.set_pixel(x, y, color)
		6:
			for j in range(pixel_num):
				var index_2: int = image_data[j] & 7
				var alpha: float = (image_data[j] >> 3) / 31.0
				var x: int = j % width
				var y: int = j / width
				var color: Color = palette.get_pal_rgbs()[index_2]
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
		7:
			for j in range(pixel_num):
				var index_2: int = (image_data[j * 2] + (image_data[j * 2 + 1] << 8)) & 0xFFFF
				var alpha: float = 1.0 if index_2 & 0x8000 != 0 else 0.0
				var red: float = ((index_2 >> 0) & 0x1F) / 31.0
				var green: float = ((index_2 >> 5) & 0x1F) / 31.0
				var blue: float = ((index_2 >> 10) & 0x1F) / 31.0
				var x: int = j % width
				var y: int = j / width
				image.set_pixel(x, y, Color(red, green, blue, alpha))

	return NDSCompanion.remove_top_left_color(image)

# Helper function to return an empty image
func get_empty_image() -> Image:
	var empty_image: Image = Image.new()
	empty_image.create(1, 1, false, Image.FORMAT_RGBA8)
	empty_image.fill(Color(0, 0, 0, 0))
	return empty_image
