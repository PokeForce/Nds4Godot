class_name BattleSprite


static func draw_image(palette_data: PackedByteArray, sprite_data: PackedByteArray) -> Image:
	var num_array1: PackedInt32Array = PackedInt32Array()
	var num_array2: PackedInt32Array = PackedInt32Array()
	var num_array3: PackedInt32Array = PackedInt32Array()

	var stream: EndianBinaryReader = EndianBinaryReader.new(palette_data)
	stream.seek(40)
	for index in range(16):
		var low_byte: int = stream.read_int8()
		var high_byte: int = stream.read_int8()
		var num: int = low_byte + (high_byte << 8)
		num_array1.append((num & 31) * 8)
		num_array2.append((num >> 5 & 31) * 8)
		num_array3.append((num >> 10 & 31) * 8)

	var bm: Image = Image.create(96, 96, false, Image.FORMAT_RGBA8)
	var bm2: Image = Image.create(98, 144, false, Image.FORMAT_RGBA8)

	stream = EndianBinaryReader.new(sprite_data)
	stream.seek(48)

	var pixel_x: int = 0
	var pixel_y: int = 0
	var pixel_xm: int = 8
	var pixel_ym:int = 8

	for index1 in range(144):
		for index2 in range(32):
			if stream.get_position() < stream.get_length():
				var current_byte: int = stream.read_int8()
				if pixel_x + 1 < bm2.get_width() and pixel_y < bm2.get_height():
					bm2.set_pixel(
						pixel_x + 1,
						pixel_y,
						int_to_color(color_to_argb(
							num_array1[current_byte >> 4],
							num_array2[current_byte >> 4],
							num_array3[current_byte >> 4]
						))
					)
				current_byte &= 0xF
				if pixel_x < bm2.get_width() and pixel_y < bm2.get_height():
					bm2.set_pixel(
						pixel_x,
						pixel_y,
						int_to_color(color_to_argb(
							num_array1[current_byte],
							num_array2[current_byte],
							num_array3[current_byte]
						))
					)
				pixel_x += 2
				if pixel_x == pixel_xm:
					pixel_x = pixel_xm - 8
					pixel_y += 1
		pixel_xm += 8
		if pixel_xm > 64:
			pixel_x = 0
			pixel_xm = 8
			pixel_ym += 8
			pixel_y = pixel_ym - 8
		else:
			pixel_x = pixel_xm - 8
			pixel_y = pixel_ym - 8

	pixel_x = 0
	pixel_y = 0
	var pixel_x2: int = 0
	var pixel_y2: int = 0

	for index in range(4096):
		bm.set_pixel(pixel_x, pixel_y, bm2.get_pixel(pixel_x2, pixel_y2))
		pixel_x += 1
		pixel_x2 += 1
		if pixel_x == 64:
			pixel_x = 0
			pixel_y += 1
		if pixel_x2 == 64:
			pixel_x2 = 0
			pixel_y2 += 1

	pixel_x = 64
	pixel_y = 0
	pixel_x2 = 0
	pixel_y2 = 64
	for index in range(256):
		bm.set_pixel(pixel_x, pixel_y, bm2.get_pixel(pixel_x2, pixel_y2))
		pixel_x += 1
		pixel_x2 += 1
		if pixel_x == 96:
			pixel_x = 64
			pixel_y += 1
		if pixel_x2 == 32:
			pixel_x2 = 0
			pixel_y2 += 1

	pixel_x = 64
	pixel_y = 8
	pixel_x2 = 32
	pixel_y2 = 64
	for index in range(256):
		bm.set_pixel(pixel_x, pixel_y, bm2.get_pixel(pixel_x2, pixel_y2))
		pixel_x += 1
		pixel_x2 += 1
		if pixel_x == 96:
			pixel_x = 64
			pixel_y += 1
		if pixel_x2 == 64:
			pixel_x2 = 32
			pixel_y2 += 1

	pixel_x = 64
	pixel_y = 16
	pixel_x2 = 0
	pixel_y2 = 72
	for index in range(256):
		bm.set_pixel(pixel_x, pixel_y, bm2.get_pixel(pixel_x2, pixel_y2))
		pixel_x += 1
		pixel_x2 += 1
		if pixel_x == 96:
			pixel_x = 64
			pixel_y += 1
		if pixel_x2 == 32:
			pixel_x2 = 0
			pixel_y2 += 1

	pixel_x = 64
	pixel_y = 24
	pixel_x2 = 32
	pixel_y2 = 72
	for index in range(256):
		bm.set_pixel(pixel_x, pixel_y, bm2.get_pixel(pixel_x2, pixel_y2))
		pixel_x += 1
		pixel_x2 += 1
		if pixel_x == 96:
			pixel_x = 64
			pixel_y += 1
		if pixel_x2 == 64:
			pixel_x2 = 32
			pixel_y2 += 1

	pixel_x = 64
	pixel_y = 32
	pixel_x2 = 0
	pixel_y2 = 80
	for index in range(256):
		bm.set_pixel(pixel_x, pixel_y, bm2.get_pixel(pixel_x2, pixel_y2))
		pixel_x += 1
		pixel_x2 += 1
		if pixel_x == 96:
			pixel_x = 64
			pixel_y += 1
		if pixel_x2 == 32:
			pixel_x2 = 0
			pixel_y2 += 1

	pixel_x = 64
	pixel_y = 40
	pixel_x2 = 32
	pixel_y2 = 80
	for index in range(256):
		bm.set_pixel(pixel_x, pixel_y, bm2.get_pixel(pixel_x2, pixel_y2))
		pixel_x += 1
		pixel_x2 += 1
		if pixel_x == 96:
			pixel_x = 64
			pixel_y += 1
		if pixel_x2 == 64:
			pixel_x2 = 32
			pixel_y2 += 1

	pixel_x = 64
	pixel_y = 48
	pixel_x2 = 0
	pixel_y2 = 88
	for index in range(256):
		bm.set_pixel(pixel_x, pixel_y, bm2.get_pixel(pixel_x2, pixel_y2))
		pixel_x += 1
		pixel_x2 += 1
		if pixel_x == 96:
			pixel_x = 64
			pixel_y += 1
		if pixel_x2 == 32:
			pixel_x2 = 0
			pixel_y2 += 1

	pixel_x = 64
	pixel_y = 56
	pixel_x2 = 32
	pixel_y2 = 88
	for index in range(256):
		bm.set_pixel(pixel_x, pixel_y, bm2.get_pixel(pixel_x2, pixel_y2))
		pixel_x += 1
		pixel_x2 += 1
		if pixel_x == 96:
			pixel_x = 64
			pixel_y += 1
		if pixel_x2 == 64:
			pixel_x2 = 32
			pixel_y2 += 1

	pixel_x = 0
	pixel_y = 64
	pixel_x2 = 0
	pixel_y2 = 96
	for index in range(2048):
		bm.set_pixel(pixel_x, pixel_y, bm2.get_pixel(pixel_x2, pixel_y2))
		pixel_x += 1
		pixel_x2 += 1
		if pixel_x == 64:
			pixel_x = 0
			pixel_y += 1
		if pixel_x2 == 64:
			pixel_x2 = 0
			pixel_y2 += 1

	pixel_x = 64
	pixel_y = 64
	pixel_x2 = 0
	pixel_y2 = 128
	for index in range(256):
		bm.set_pixel(pixel_x, pixel_y, bm2.get_pixel(pixel_x2, pixel_y2))
		pixel_x += 1
		pixel_x2 += 1
		if pixel_x == 96:
			pixel_x = 64
			pixel_y += 1
		if pixel_x2 == 32:
			pixel_x2 = 0
			pixel_y2 += 1

	pixel_x = 64
	pixel_y = 72
	pixel_x2 = 32
	pixel_y2 = 128
	for index in range(256):
		bm.set_pixel(pixel_x, pixel_y, bm2.get_pixel(pixel_x2, pixel_y2))
		pixel_x += 1
		pixel_x2 += 1
		if pixel_x == 96:
			pixel_x = 64
			pixel_y += 1
		if pixel_x2 == 64:
			pixel_x2 = 32
			pixel_y2 += 1

	pixel_x = 64
	pixel_y = 80
	pixel_x2 = 0
	pixel_y2 = 136
	for index in range(256):
		bm.set_pixel(pixel_x, pixel_y, bm2.get_pixel(pixel_x2, pixel_y2))
		pixel_x += 1
		pixel_x2 += 1
		if pixel_x == 96:
			pixel_x = 64
			pixel_y += 1
		if pixel_x2 == 32:
			pixel_x2 = 0
			pixel_y2 += 1

	pixel_x = 64
	pixel_y = 88
	pixel_x2 = 32
	pixel_y2 = 136
	for index in range(256):
		bm.set_pixel(pixel_x, pixel_y, bm2.get_pixel(pixel_x2, pixel_y2))
		pixel_x += 1
		pixel_x2 += 1
		if pixel_x == 96:
			pixel_x = 64
			pixel_y += 1
		if pixel_x2 == 64:
			pixel_x2 = 32
			pixel_y2 += 1
			
	return bm

static func color_to_argb(r: int, g: int, b: int) -> int:
	return (255 << 24) | (r << 16) | (g << 8) | b

static func int_to_color(argb: int) -> Color:
	var a: float = ((argb >> 24) & 0xFF) / 255.0
	var r: float = ((argb >> 16) & 0xFF) / 255.0
	var g: float = ((argb >> 8) & 0xFF) / 255.0
	var b: float = (argb & 0xFF) / 255.0
	return Color(r, g, b, a)
