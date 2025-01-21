extends Node

class_name FileNameTable
class Folder:
	
	var folders: Dictionary[String, Folder] = {}
	var files: Array[String] = []
	var first_id: int = 0
	var name: String = ""
	var next_folder_id: int = 0
	
	func _init(name: String = "", first_id: int = 0) -> void:
		self.folders = {}
		self.files = []
		self.first_id = first_id
		self.name = name

	# Get the list of files in the folder
	func get_files() -> Array[String]:
		return files

	# Get the dictionary of folders in the folder
	func get_folders() -> Dictionary[String, Folder]:
		return folders

	# Get the first file ID in the folder
	func get_first_id() -> int:
		return first_id

	# Find the file ID for the given filename
	func get_id_of(name: String) -> int:
		var path_stream: Array[String] = []
		for part in name.split("/"):
			path_stream.append(part)
		return _find_filename_in_folder(path_stream, self)

	# Find the filename in the given folder
	func _find_filename_in_folder(requested_path: Array[String], search_folder: Folder) -> int:
		var path_part: String = requested_path[0]
		if requested_path.size() == 1:
			if path_part in search_folder.files:
				return search_folder.first_id + search_folder.files.find(path_part)
			else:
				return -1

		for subfolder_name: String in search_folder.folders.keys():
			if subfolder_name == path_part:
				var subfolder: Folder = search_folder.folders[subfolder_name]
				requested_path.remove_at(0)
				return _find_filename_in_folder(requested_path, subfolder)

		return -1

	# Find the subfolder by path
	func get_subfolder(path: String) -> Folder:
		var path_stream: Array[String] = path.split("/")
		return _find_subfolder_in_folder(path_stream, self)

	# Attempt to find subfolder in the given folder
	func _find_subfolder_in_folder(requested_path: Array[String], search_folder: Folder) -> Folder:
		var path_part: String = requested_path[0]

		for subfolder_name: String in search_folder.folders.keys():
			if subfolder_name == path_part:
				var subfolder: Folder = search_folder.folders[subfolder_name]
				if requested_path.size() == 1:
					return subfolder
				else:
					requested_path.remove_at(0)
					return _find_subfolder_in_folder(requested_path, subfolder)

		return null

	# Get the filename of the file with the given ID
	func get_filename_of(id: int) -> String:
		var result: Array[String] = _find_id_in_folder(id, [], self)
		if result:
			return _join_array(result, "/")
		return ""

	func _join_array(arr: Array[String], sep: String) -> String:
		var joined_string: String = ""
		for i in range(arr.size()):
			joined_string += arr[i]
			if i < arr.size() - 1:  
				joined_string += sep
		return joined_string
		
	func _find_id_in_folder(id: int, path_so_far: Array[String], search_folder: Folder) -> Array[String]:
		var first_id: int = search_folder.first_id
		if first_id <= id and id < first_id + search_folder.files.size():
			var filename: String = search_folder.files[id - first_id]
			path_so_far.append(filename)
			return path_so_far

		for subfolder_name: String in search_folder.folders.keys():
			var subfolder: Folder = search_folder.folders[subfolder_name]
			var current_path: Array[String] = path_so_far.duplicate()
			current_path.append(subfolder_name)
			var result: Array[String] = _find_id_in_folder(id, current_path, subfolder)
			if result:
				return result

		return []

	func to_string_list(indent: int) -> Array[String]:
		return _to_string_list_helper(indent)

	func _to_string_list_helper(indent: int) -> Array[String]:
		var result: Array[String] = []
		var indent_string: String = " ".repeat(indent + 1) 
		
		for i in range(files.size()):
			var filename: String = files[i]
			var fid: int = first_id + i
			result.append(indent_string + str(fid) + ": " + filename)

		for folder_name: String in folders.keys():
			var folder: Folder = folders[folder_name]
			result.append(indent_string + folder_name + "/")
			result.append_array(folder._to_string_list_helper(indent + 4))
		
		return result


	func _equals(other: Folder) -> bool:
		return first_id == other.first_id and folders == other.folders and files == other.files and name == other.name

# Static functions for handling folder loading/saving
static func load(fnt: PackedByteArray) -> Folder:
	return _load_folder(fnt, 0xF000, "root")

static func _load_folder(fnt: PackedByteArray, folder_id: int, name: String) -> Folder:
	var buffer: NDSBuffer = NDSBuffer.new()
	buffer.set_data(fnt)
	
	var folder: Folder = Folder.new(name)
	var offset: int = 8 * (folder_id & 0xFFF)
	buffer.set_position(offset)
	var entries_table_offset: int = buffer.get_32()
	var file_id: int = buffer.get_16()

	folder.first_id = file_id
	buffer.set_position(entries_table_offset)
	while true:
		var control: int = buffer.get_8()
		if control == 0:
			break

		var length: int = control & 0x7F
		var is_folder: int = control & 0x80

		name = buffer.get_bytes(length).get_string_from_utf8()

		if is_folder == 0x80:
			var sub_folder_id: int = buffer.get_16()
			folder.folders[name] = _load_folder(fnt, sub_folder_id, name)
		else:
			folder.files.append(name)

	return folder

static func _count_folders_in(folder: Folder) -> int:
	var folder_count: int = 1
	for subfolder: Folder in folder.folders.values():
		folder_count += _count_folders_in(subfolder)
	return folder_count

# Interface for FileProcessingData
class FileProcessingData:
	var file_id: int
	var parent_folder_id: int
	var fnt_entry: NDSBuffer

	func get_file_id() -> int:
		return file_id

	func get_parent_folder_id() -> int:
		return parent_folder_id

	func get_fnt_entry() -> NDSBuffer:
		return fnt_entry
