class_name FATBEntry

var start_offset: int = 0
var end_offset: int = 0
var entry_size: int = 0
	
func _init(start_offset: int, end_offset: int, entry_size: int) -> void:
	self.start_offset = start_offset
	self.end_offset = end_offset
	self.entry_size = entry_size
