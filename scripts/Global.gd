extends Node

var selected_suspect: Dictionary = {}
var suspect_already_selected := false
var current_odp: Dictionary = {}
var kept_suspects: Array = []

var tutorials_completed: Dictionary = {
	# nanti ditambahin semua dialog
	"prolog": false,
	"suspect_menu": false,
	"stack_menu": false,
	"queue_orang_menu": false,
	"queue_fax_menu": false,
	"hasmap_menu": false,
	"choose_suspect_menu": false,
}

# ---------------------------------------------------------------------------------------------------
# Character Loader
# ---------------------------------------------------------------------------------------------------

enum Broker {
	STACK = 0, QUEUE, FAX, HASH_MAP
}

# --- Configuration ---
var json_path := "res://assets/characters/characters.json"
var total_to_use := 40           # how many suspects to pull from the full list
var min_per_list := [5, 5, 5, 5] # minimum for each of the 4 lists
var max_per_list := [15, 15, 15, 15] # maximum for each of the 4 lists

# --- Output ---
var lists: Array[Array] = [[], [], [], []]

func _ready() -> void:
	load_and_split()

func load_and_split() -> void:
	var suspects := _load_json(json_path)
	if suspects.is_empty():
		push_error("SuspectLoader: failed to load or empty JSON")
		return

	# Shuffle and trim to total_to_use
	suspects.shuffle()
	if suspects.size() > total_to_use:
		suspects = suspects.slice(0, total_to_use)

	# Randomly split into 4 lists within [min, max] per list
	var split := _random_split(suspects.size(), min_per_list, max_per_list)
	if split.is_empty():
		push_error("SuspectLoader: could not produce a valid split")
		return

	lists = [[], [], [], []]
	var cursor := 0
	for i in 4:
		lists[i] = suspects.slice(cursor, cursor + split[i])
		cursor += split[i]

	# Debug print
	for i in 4:
		print("List %d: %d suspects" % [i, lists[i].size()])

func get_list(index: Broker) -> Array:
	if index < 0 or index >= lists.size():
		push_error("SuspectLoader: invalid list index %d" % index)
		return []
	return lists[index]

# --- Internal ---

func _load_json(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("SuspectLoader: file not found: %s" % path)
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("SuspectLoader: JSON root must be an array")
		return []
	return parsed

func _random_split(total: int, mins: Array, maxs: Array) -> Array:
	# Check feasibility
	var min_sum: int = 0
	var max_sum: int = 0
	for i in 4:
		min_sum += mins[i]
		max_sum += maxs[i]

	if total < min_sum or total > max_sum:
		push_error("SuspectLoader: total=%d is outside feasible range [%d, %d]" % [total, min_sum, max_sum])
		return []

	# Start everyone at their minimum, then distribute the remainder randomly
	var sizes := mins.duplicate()
	var remaining := total - min_sum
	var headroom := []
	for i in 4:
		headroom.append(maxs[i] - mins[i])

	while remaining > 0:
		# Pick a random list that still has room
		var candidates := []
		for i in 4:
			if headroom[i] > 0:
				candidates.append(i)
		if candidates.is_empty():
			break
		var pick: int = candidates[randi() % candidates.size()]
		sizes[pick] += 1
		headroom[pick] -= 1
		remaining -= 1

	return sizes
