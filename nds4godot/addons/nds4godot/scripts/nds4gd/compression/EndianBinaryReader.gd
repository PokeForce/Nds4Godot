class_name EndianBinaryReader

var data: PackedByteArray
var position: int = 0

func _init(_data: PackedByteArray) -> void:
	data = _data

func skip(amount: int) -> void:
	position += amount

func seek(pos: int) -> void:
	position = pos

func read_bytes(num: int) -> PackedByteArray:
	var tmp: PackedByteArray = data.slice(position, position + num)
	position += num
	return tmp

func read_string(num: int) -> String:
	var tmp: PackedByteArray = data.slice(position, position + num)
	position += num
	return tmp.get_string_from_ascii()

func read_int32() -> int:
	var value: int = data[position] + (data[position + 1] << 8) + (data[position + 2] << 16) + (data[position + 3] << 24)
	position += 4
	return value

func read_int16() -> int:
	var value: int = data[position] + (data[position + 1] << 8)
	position += 2
	return value
	
func read_int8() -> int:
	var value: int = data[position]
	position += 1
	return value

func get_position() -> int:
	return position

func get_length() -> int:
	return data.size()
