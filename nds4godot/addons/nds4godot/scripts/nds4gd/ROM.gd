extends Node

class_name ROM

# Title of the game, typically represented as a string
var title: String = ""

# Unique game code identifier
var game_code: String = ""

# Developer code identifying the developer
var developer_code: String = ""

# Unit code, typically represents the hardware unit
var unit_code: int = 0

# Seed used for encryption
var encryption_seed: int = 0

# Capacity of the device, represented as a byte
var device_capacity: int = 0

# Reserved byte arrays for future use or padding
var reserved1: PackedByteArray = PackedByteArray() 
var reserved2: int = 0  # Single byte reserved

# Region of the system, usually represented as an int
var system_region: int = 0

# Version of the ROM
var rom_version: int = 0

# Flag to determine if the game should auto-start
var auto_start_flag: int = 0

# ARM9 code block offsets and lengths
var arm9_offset: int = 0
var arm9_entry_address: int = 0
var arm9_load_address: int = 0
var arm9_length: int = 0

# ARM7 code block offsets and lengths
var arm7_offset: int = 0
var arm7_entry_address: int = 0
var arm7_load_address: int = 0
var arm7_length: int = 0

# File Name Table (FNT) offset and length
var fnt_offset: int = 0
var fnt_length: int = 0

# File Allocation Table (FAT) offset and length
var fat_offset: int = 0
var fat_length: int = 0

# Y9 section offset and length
var y9_offset: int = 0
var y9_length: int = 0

# Y7 section offset and length
var y7_offset: int = 0
var y7_length: int = 0

# Card control register settings (normal and secure)
var normal_card_control_register_settings: int = 0
var secure_card_control_register_settings: int = 0

# Icon/banner offset and length
var icon_banner_offset: int = 0

# Secure area CRC, recalculated upon saving
var secure_area_crc: int = 0

# Timeout for secure transfer
var secure_transfer_timeout: int = 0

# Auto-load flags for ARM9 and ARM7
var arm9_autoload: int = 0
var arm7_autoload: int = 0

# Secure disable bytes
var secure_disable: PackedByteArray = PackedByteArray()

# ROM size or RSA signature offset (represented as a long in the original, mapped to int in GDScript)
var rom_size_or_rsa_sig_offset: int = 0

# Header length
var header_length: int = 0

# Padding fields
var padding_088h: PackedByteArray = PackedByteArray()
var nintendo_logo: PackedByteArray = PackedByteArray()

# CRC of the Nintendo logo
var nintendo_logo_crc: int = 0

# Header CRC
var header_crc: int = 0

# Debug ROM offset, length, and address
var debug_rom_offset: int = 0
var debug_rom_length: int = 0
var debug_rom_address: int = 0

# Additional padding
var padding_16Ch: PackedByteArray = PackedByteArray()
var padding_200h: PackedByteArray = PackedByteArray()

# RSA Signature
var rsa_signature: PackedByteArray = PackedByteArray()

# ARM9 and ARM7 code blocks
var arm9: PackedByteArray = PackedByteArray()
var arm7: PackedByteArray = PackedByteArray()

# File Name Table (FNT) and File Allocation Table (FAT)
var fnt: PackedByteArray = PackedByteArray()
var fat: PackedByteArray = PackedByteArray()

# Y9 and Y7 sections
var y9: PackedByteArray = PackedByteArray()
var y7: PackedByteArray = PackedByteArray()

# Icon and banner data
var icon_banner: PackedByteArray = PackedByteArray()

# Debug ROM data
var debug_rom: PackedByteArray = PackedByteArray()

# ARM9 post data, stored as an array of integers
var arm9_post_data: PackedInt32Array = PackedInt32Array()

var filenames: FileNameTable.Folder = FileNameTable.Folder.new()
var files: Array[PackedByteArray] = []
var sorted_file_ids: Array[int] = []

var ICON_BANNER_LENGTHS: Dictionary = {
	0x0001: 0x840,
	0x0002: 0x940,
	0x0003: 0x1240,
	0x0103: 0x23C0
}

func _init(data: PackedByteArray) -> void:
	var buffer: NDSBuffer = NDSBuffer.new()
	buffer.set_data(data)
	buffer.set_position(0)

	var file_length: int = data.size()

	# Read the ROM header
	_read_header(buffer, file_length)

	# Read RSA signature
	var real_sig_offset: int = 0
	if file_length >= 0x1004:
		buffer.set_position(0x1000)
		real_sig_offset = buffer.get_32()

	if real_sig_offset == 0 and file_length > rom_size_or_rsa_sig_offset:
		real_sig_offset = rom_size_or_rsa_sig_offset

	if real_sig_offset != 0:
		buffer.set_position(real_sig_offset)
		rsa_signature = buffer.get_bytes(min(file_length, real_sig_offset + 0x88))
	else:
		rsa_signature = PackedByteArray()

	# ARM9, ARM7, FNT, FAT, Y9, Y7, Icon Banner, and Debug ROM
	buffer.set_position(arm9_offset)
	_read_arm9(buffer, arm9_length)

	buffer.set_position(arm7_offset)
	_read_arm7(buffer, arm7_length)

	buffer.set_position(fnt_offset)
	fnt = buffer.get_bytes(fnt_length)

	buffer.set_position(fat_offset)
	fat = buffer.get_bytes(fat_length)

	buffer.set_position(y9_offset)
	_read_y9(buffer, y9_length)

	buffer.set_position(y7_offset)
	_read_y7(buffer, y7_length)

	_read_icon_banner(buffer)
	_read_debug_rom(buffer)

	# Post-data section
	_process_arm9_post_data(buffer)

	# Process FAT and overlay tables if they exist
	if fnt.size() != 0:
		filenames = FileNameTable.load(fnt)
	else:
		filenames = FileNameTable.Folder.new()

	files = []
	sorted_file_ids = []

	if fat.size() != 0:
		_process_fat(buffer)

func get_file_by_name(filename: String) -> PackedByteArray:
	var fid: int = filenames.get_id_of(filename)
	if fid == -1:
		push_error("Cannot find file ID of \"" + filename + "\"")
		return PackedByteArray()  
	return files[fid]

func _process_fat(buffer: NDSBuffer) -> void:
	# Initialize a temporary buffer for the FAT
	var fat_buf: NDSBuffer = NDSBuffer.new()
	fat_buf.set_data(fat)
	
	var offset_to_id: Dictionary = {}
	var offset_to_id_keys: Array = []
	
	for i in range(fat.size() / 8):
		var start_offset: int = fat_buf.get_32()
		var end_offset: int = fat_buf.get_32()
		
		buffer.set_position(start_offset)
		files.append(buffer.get_bytes(end_offset - start_offset)) 
		
		offset_to_id[start_offset] = i
		offset_to_id_keys.append(start_offset)
	
	# Sort the file IDs by start_offset
	offset_to_id_keys.sort()
	sorted_file_ids = []
	
	for key: int in offset_to_id_keys:
		sorted_file_ids.append(offset_to_id[key])

# Header reading method using NDSBuffer
func _read_header(buffer: NDSBuffer, file_length: int) -> void:
	title = buffer.get_bytes(12).get_string_from_utf8().strip_edges()
	game_code = buffer.get_bytes(4).get_string_from_utf8()
	developer_code = buffer.get_bytes(2).get_string_from_utf8()

	unit_code = buffer.get_8()
	encryption_seed = buffer.get_8()
	device_capacity = buffer.get_8()
	reserved1 = buffer.get_bytes(7)
	reserved2 = buffer.get_8()
	system_region = buffer.get_8()
	rom_version = buffer.get_8()
	auto_start_flag = buffer.get_8()

	arm9_offset = buffer.get_32()
	arm9_entry_address = buffer.get_32()
	arm9_load_address = buffer.get_32()
	arm9_length = buffer.get_32()

	arm7_offset = buffer.get_32()
	arm7_entry_address = buffer.get_32()
	arm7_load_address = buffer.get_32()
	arm7_length = buffer.get_32()

	fnt_offset = buffer.get_32()
	fnt_length = buffer.get_32()
	fat_offset = buffer.get_32()
	fat_length = buffer.get_32()

	y9_offset = buffer.get_32()
	y9_length = buffer.get_32()
	y7_offset = buffer.get_32()
	y7_length = buffer.get_32()

	normal_card_control_register_settings = buffer.get_32()
	secure_card_control_register_settings = buffer.get_32()

	icon_banner_offset = buffer.get_32()
	secure_area_crc = buffer.get_16()
	secure_transfer_timeout = buffer.get_16()
	arm9_autoload = buffer.get_32()
	arm7_autoload = buffer.get_32()
	secure_disable = buffer.get_bytes(8)

	rom_size_or_rsa_sig_offset = buffer.get_32()
	header_length = buffer.get_32()

	padding_088h = buffer.get_bytes(0x38)
	nintendo_logo = buffer.get_bytes(0x9C)
	nintendo_logo_crc = buffer.get_16()
	header_crc = buffer.get_16()
	debug_rom_offset = buffer.get_32()
	debug_rom_length = buffer.get_32()
	debug_rom_address = buffer.get_32()
	padding_16Ch = buffer.get_bytes(0x94)
	padding_200h = buffer.get_bytes(file_length - arm9_offset)

func _read_arm9(buffer: NDSBuffer, length: int) -> void:
	arm9 = buffer.get_bytes(length)

func _read_arm7(buffer: NDSBuffer, length: int) -> void:
	arm7 = buffer.get_bytes(length)

func _read_y9(buffer: NDSBuffer, length: int) -> void:
	y9 = buffer.get_bytes(length)

func _read_y7(buffer: NDSBuffer, length: int) -> void:
	y7 = buffer.get_bytes(length)

func _read_icon_banner(buffer: NDSBuffer) -> void:
	if icon_banner_offset != 0:
		buffer.set_position(icon_banner_offset)
		var val: int = buffer.get_16()
		var icon_banner_length: int = ICON_BANNER_LENGTHS.get(val, ICON_BANNER_LENGTHS[0x0001])
		buffer.set_position(icon_banner_offset)
		icon_banner = buffer.get_bytes(icon_banner_length)
	else:
		icon_banner = PackedByteArray()

func _read_debug_rom(buffer: NDSBuffer) -> void:
	if debug_rom_offset != 0:
		buffer.set_position(debug_rom_offset)
		debug_rom = buffer.get_bytes(debug_rom_length)
	else:
		debug_rom = PackedByteArray()

func _process_arm9_post_data(buffer: NDSBuffer) -> void:
	var arm9_post_data_array: Array[int] = []
	while true:
		var extra_data: PackedByteArray = buffer.get_bytes(4)
		if extra_data == PackedByteArray([0x21, 0x06, 0xC0, 0xDE]):
			arm9_post_data_array.append_array(extra_data)
			arm9_post_data_array.append_array(buffer.get_bytes(8))
		else:
			break
	arm9_post_data = PackedInt32Array(arm9_post_data_array)

# Function to read a Nintendo DS ROm from a .nds file on disk
static func from_file(file_path: String) -> ROM:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file:
		return ROM.new(file.get_buffer(file.get_length()))
	return null
