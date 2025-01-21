class_name FileImageEntry

var data: PackedByteArray = []
	
func _init(data: Array) -> void:
	self.data = PackedByteArray(data[1])
