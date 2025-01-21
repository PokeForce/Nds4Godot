class_name Palette

var offset := 0
var color0 := 0
var pal: PackedColorArray = PackedColorArray()

static func to_bgr555_array(bytes: PackedByteArray) -> Array:
	var palette: PackedColorArray = PackedColorArray()
	var i: int = 0
	while i < bytes.size() - 1:
		var color: Color = to_bgr555(bytes[i], bytes[i + 1])
		palette.append(color)
		i += 2
	return palette

static func from_bgr555(p: PackedColorArray) -> PackedByteArray:
	var b: PackedByteArray = PackedByteArray()
	for color in p:
		var num: int = 0
		num += int(color.r * 31)
		num += int(color.g * 31) << 5
		num += int(color.b * 31) << 10
		b.append(num & 0xFF)
		b.append((num >> 8) & 0xFF)
	return b

static func to_bgr555(byte1: int, byte2: int) -> Color:
	var num: int = (byte2 << 8) + byte1
	var r: float = ((num & 0x1F) * 8) / 255.0
	var g: float = (((num >> 5) & 0x1F) * 8) / 255.0
	var b: float = (((num >> 10) & 0x1F) * 8) / 255.0
	return Color(r, g, b)


func get_pal_rgbs() -> PackedColorArray:
	return pal
