class_name NDSBuffer

var data: PackedByteArray
var position: int = 0

func set_data(data: PackedByteArray) -> void:
	self.data = data

func set_position(position: int) -> void:
	self.position = position

func get_position() -> int:
	return self.position

func get_8() -> int:
	var value: int = data[position]
	position += 1
	return value

func get_16() -> int:
	var value: int = data[position] + (data[position + 1] << 8)
	position += 2
	return value

func get_32() -> int:
	var value: int = data[position] + (data[position + 1] << 8) + (data[position + 2] << 16) + (data[position + 3] << 24)
	position += 4
	return value

func get_bytes(size: int) -> PackedByteArray:
	var value: PackedByteArray = data.slice(position, position + size)
	position += size
	return value

func get_string(size: int) -> String:
	return data.slice(position, position + size).get_string_from_utf8().strip_edges()

func skip(size: int) -> void:
	position += size
