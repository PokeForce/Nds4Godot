class_name IOUtils

static func to_nds_u24(buffer: PackedByteArray, offset: int) -> int:
	return (buffer[offset] & 0xFF) | ((buffer[offset + 1] & 0xFF) << 8) | ((buffer[offset + 2] & 0xFF) << 16)

static func to_nds_s32(buffer: PackedByteArray, offset: int) -> int:
	var byte_buffer: NDSBuffer = NDSBuffer.new()
	byte_buffer.set_data(buffer)
	byte_buffer.set_position(offset)
	return byte_buffer.get_32()

static func from_nds_u32(value: int) -> PackedByteArray:
	var byte_buffer: NDSBuffer = NDSBuffer.new()
	byte_buffer.put_32(value)
	return byte_buffer.get_data()
