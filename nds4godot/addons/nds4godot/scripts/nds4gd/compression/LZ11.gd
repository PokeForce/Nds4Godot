class_name LZ11

# Function to decompress LZ11 compressed data
static func decompress_lz11(input_stream: EndianBinaryReader, in_length: int) -> PackedByteArray:
	var output_bytes: PackedByteArray = PackedByteArray()  # Output array to store decompressed data
	var num1: int = 0
	var num2: int = input_stream.read_int8()

	# Check if the input stream starts with the expected LZ11 magic byte (0x11)
	if num2 != 17:
		print("Invalid data stream")
		return PackedByteArray()

	# Read the total output size (3 bytes)
	var buffer1: PackedByteArray = input_stream.read_bytes(3)
	var total_out_size: int = IOUtils.to_nds_u24(buffer1, 0)  # Convert 3 bytes to a 24-bit integer
	var read_bytes: int = num1 + 4  # Track how many bytes have been read

	# If total_out_size is zero, read the next 4 bytes for the true size
	if total_out_size == 0:
		var buffer2: PackedByteArray = input_stream.read_bytes(4)
		total_out_size = IOUtils.to_nds_s32(buffer2, 0)  # Convert the 4-byte data to an integer
		read_bytes += 4

	# Initialize the sliding window buffer and variables
	var length: int = 4096
	var num_array: PackedByteArray = PackedByteArray()
	num_array.resize(length)
	var index1: int = 0
	var current_out_size: int = 0
	var num3: int = 0
	var num4: int = 1

	# Main decompression loop
	while current_out_size < total_out_size:
		# Load a new control byte when needed (each bit in num3 controls how to process upcoming data)
		if num4 == 1:
			if read_bytes >= in_length:
				print("Not enough data")
				return PackedByteArray()
			num3 = input_stream.read_int8()  # Read control byte
			read_bytes += 1
			if num3 < 0:
				print("Stream too short")
				return PackedByteArray()
			num4 = 128  # Reset num4 to its highest bit
		else:
			num4 >>= 1  # Shift to the next bit

		# Check if the next block is compressed (num3 & num4 > 0) or uncompressed (num3 & num4 == 0)
		if (num3 & num4) > 0:
			# Compressed block processing
			if read_bytes >= in_length:
				print("Not enough data")
				return PackedByteArray()
			var num5: int = input_stream.read_int8()
			read_bytes += 1

			# Variable to store the amount of bytes to copy and how far back to copy from
			var num7: int
			var num8: int

			# Match the higher nibble of num5 to determine the decompression case
			match num5 >> 4:
				0:
					# Case for larger runs (length >= 17)
					if read_bytes + 1 >= in_length:
						print("Not enough data")
						return PackedByteArray()
					var num9: int = input_stream.read_int8()
					read_bytes += 1
					var num11: int = input_stream.read_int8()
					read_bytes += 1
					if num11 < 0:
						print("Stream too short")
						return PackedByteArray()
					num7 = ((num5 & 15) << 4 | (num9 >> 4)) + 17  # Length of the run
					num8 = ((num9 & 15) << 8 | num11) + 1  # Distance to copy from
				1:
					# Case for even larger runs (length >= 273)
					if read_bytes + 2 >= in_length:
						print("Not enough data")
						return PackedByteArray()
					var num12: int = input_stream.read_int8()
					read_bytes += 1
					var num14: int = input_stream.read_int8()
					read_bytes += 1
					var num16: int = input_stream.read_int8()
					read_bytes += 1
					if num16 < 0:
						print("Stream too short")
						return PackedByteArray()
					num7 = ((num5 & 15) << 12 | (num12 << 4) | (num14 >> 4)) + 273  # Length
					num8 = ((num14 & 15) << 8 | num16) + 1  # Distance
				_:
					# Default case (shorter runs)
					if read_bytes >= in_length:
						print("Not enough data")
						return PackedByteArray()
					var num17: int = input_stream.read_int8()
					read_bytes += 1
					if num17 < 0:
						print("Stream too short")
						return PackedByteArray()
					num7 = ((num5 & 240) >> 4) + 1  # Length
					num8 = ((num5 & 15) << 8 | num17) + 1  # Distance

			# Error handling if the distance to copy from exceeds the current output size
			if num8 > current_out_size:
				print("Invalid data")
				return PackedByteArray()

			# Copy the run from the sliding window buffer
			var num18: int = index1 + length - num8
			for i in range(num7):
				var num19: int = num_array[num18 % length]
				num18 += 1
				output_bytes.append(num19)
				num_array[index1] = num19
				index1 = (index1 + 1) % length
			current_out_size += num7
		else:
			# Uncompressed block processing
			if read_bytes >= in_length:
				print("Not enough data")
				return PackedByteArray()
			var num20: int = input_stream.read_int8()
			read_bytes += 1
			if num20 < 0:
				print("Stream too short")
				return PackedByteArray()
			output_bytes.append(num20)
			current_out_size += 1
			num_array[index1] = num20
			index1 = (index1 + 1) % length

	# Handle the case where there's too much input
	if read_bytes < in_length and (read_bytes ^ (read_bytes & 3)) + 4 < in_length:
		print("Too much input")
		return PackedByteArray()

	return output_bytes
