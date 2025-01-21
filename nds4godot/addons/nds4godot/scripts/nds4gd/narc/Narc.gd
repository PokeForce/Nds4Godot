extends RefCounted

class_name Narc

# Variables to store NARC file metadata
var narc_size: int = 0
var num_entries: int = 0
var fatb_size: int = 0
var fntb_size: int = 0
var fimg_size: int = 0
var fimg_offset: int = 0

# Arrays to store FATB (File Allocation Table) and FIMG (File Image) entries
var fatb_entry: Array[FATBEntry] = []
var fimg_entry: Array[FileImageEntry] = []

# Initialization function to decode NARC file data
func _init(data: PackedByteArray) -> void:
	# Create a stream to read from the PackedByteArray
	var stream: StreamPeerBuffer = StreamPeerBuffer.new()
	stream.data_array = data

	# Skip the first 8 bytes (NARC header)
	stream.seek(8)

	# Read the total size of the NARC file
	narc_size = stream.get_32()

	# Skip another 8 bytes (to the FATB section)
	stream.seek(stream.get_position() + 8)

	# Read the FATB section size and the number of entries
	fatb_size = stream.get_32()
	num_entries = stream.get_32()

	# Loop through the FATB entries and store their start, end offsets and size
	for i in range(num_entries):
		var start_offset: int = stream.get_32()
		var end_offset: int = stream.get_32()
		var entry_size: int = end_offset - start_offset
		# Store the FATB entry
		fatb_entry.append(FATBEntry.new(start_offset, end_offset, entry_size))

	# Skip the FNTB section pointer
	stream.seek(stream.get_position() + 4)

	# Read the FNTB section size and skip to the FIMG section
	fntb_size = stream.get_32()
	stream.seek(stream.get_position() + fntb_size)

	# Store the FIMG section offset and read its size
	fimg_offset = stream.get_position()
	stream.seek(stream.get_position() + 4)
	fimg_size = stream.get_32()

	# Loop through the FATB entries and read the associated FIMG data
	for i in range(num_entries):
		# Calculate the absolute offset for the FIMG entry using FATB data
		var offset: int = fimg_offset + fatb_entry[i].start_offset
		stream.seek(offset)

		# Read the FIMG entry data
		var entry_data: Array = stream.get_data(fatb_entry[i].entry_size)
		
		# Store the FIMG entry
		fimg_entry.append(FileImageEntry.new(entry_data))
