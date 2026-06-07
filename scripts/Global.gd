extends Node

var selected_suspect: Dictionary = {}
var suspect_already_selected := false
var current_odp: Dictionary = {}
var kept_suspects: Array = []
var selected_kept_suspect: Dictionary = {}

var revealed_fields: Array[String] = []

const MAX_KEPT_SUSPECTS := 6

var warning_flags: Dictionary = {
	"suspect_list_almost_full": false,
	"suspect_list_full": false
}

# ---------------------------------------------------------------------------------------------------
# Data Manager
# ---------------------------------------------------------------------------------------------------
var curr_stack_data: Array = []

# ---------------------------------------------------------------------------------------------------
# Tutorial / Dialogue State
# ---------------------------------------------------------------------------------------------------

var tutorial_seen: Dictionary = {}

var tutorials_completed: Dictionary = {
	"prolog": false,
	"suspect_menu": false,
	"stack_menu": false,
	"queue_orang_menu": false,
	"queue_fax_menu": false,
	"hashmap_menu": false,
	"choose_suspect_menu": false,
}
# ---------------------------------------------------------------------------------------------------
# Data Manager
# ---------------------------------------------------------------------------------------------------

var curr_stack_data: Array = []


# ---------------------------------------------------------------------------------------------------
# Character Loader
# ---------------------------------------------------------------------------------------------------

enum Broker {
	STACK = 0, QUEUE, FAX, HASH_MAP
}

# --- Configuration ---
var json_path := "res://assets/characters/characters.json"
var total_to_use := 50           # how many suspects to pull from the full list
var min_per_list := [5, 5, 5, 5] # minimum for each of the 4 lists
var max_per_list := [40, 40, 40, 10] # maximum for each of the 4 lists

# --- Output ---
var lists: Array[Array] = [[], [], [], []]
var amount: Array[Array] = [[], [], [], []]

func load_and_split(guaranteed: Dictionary = {}) -> void:
	var suspects := _load_json(json_path)
	if suspects.is_empty():
		push_error("SuspectLoader: failed to load or empty JSON")
		return
		
	# Normalize id to int for every suspect
	for s in suspects:
		s["id"] = int(s["id"])

	# Shuffle and trim to total_to_use
	suspects.shuffle()
	if suspects.size() > total_to_use:
		suspects = suspects.slice(0, total_to_use)
		
	# Ensure guaranteed suspect is in the pool
	if not guaranteed.is_empty():
		guaranteed["id"] = int(guaranteed["id"])
		var already_in := suspects.any(func(s): return s["id"] == guaranteed["id"])
		if not already_in:
			# Replace a random entry to keep total_to_use intact
			suspects[randi() % suspects.size()] = guaranteed

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

	# Ensure guaranteed suspect is in at least one list
	if not guaranteed.is_empty():
		var found := false
		for lst in lists:
			for s in lst:
				if s["id"] == guaranteed["id"]:
					found = true
					break
			if found:
				break
		if not found:
			# Insert into a random list, replacing a random entry there
			var target_list := randi() % 4
			lists[target_list][randi() % lists[target_list].size()] = guaranteed
		for i in 4:
			for j in lists[i].size():
				if lists[i][j]["id"] == guaranteed["id"]:
					print("Guaranteed suspect '%s' is in list %d at index %d" % [guaranteed["name"], i, j])
					for key in lists[i][j]:
						print("  %s: %s" % [key, lists[i][j][key]])
	else:
		print("Something wrong on guaranteed suspect")
			
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
	
# ---------------------------------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------------------------------

func reset():
	lists = [[], [], [], []]
	selected_suspect = {}
	suspect_already_selected = false
	current_odp = {}
	kept_suspects = []

	tutorials_completed = {
		"prolog": false,
		"suspect_menu": false,
		"stack_menu": false,
		"queue_orang_menu": false,
		"queue_fax_menu": false,
		"hasmap_menu": false,
		"choose_suspect_menu": false,
	}
