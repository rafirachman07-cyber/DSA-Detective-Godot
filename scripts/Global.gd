extends Node

# ---------------------------------------------------------------------------------------------------
# Main Game State
# ---------------------------------------------------------------------------------------------------

var selected_suspect: Dictionary = {} # ODP / target utama
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
# Tutorial / Dialogue State
# ---------------------------------------------------------------------------------------------------

var tutorial_seen: Dictionary = {}


#nandain scene dialog yg belum sama yg udah user lewatin 
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



func has_seen_tutorial(key: String) -> bool:
	return tutorial_seen.get(key, false)


func mark_tutorial_seen(key: String) -> void:
	tutorial_seen[key] = true


func is_tutorial_completed(key: String) -> bool:
	return tutorials_completed.get(key, false)


func mark_tutorial_completed(key: String) -> void:
	tutorials_completed[key] = true


# ---------------------------------------------------------------------------------------------------
# Broker / Character Loader
# ---------------------------------------------------------------------------------------------------

enum Broker {
	STACK = 0,
	QUEUE = 1,
	FAX = 2,
	HASH_MAP = 3
}

var json_path := "res://assets/characters/characters.json"

var total_to_use := 50
var min_per_list := [5, 5, 5, 5]
var max_per_list := [40, 40, 40, 10]

var lists: Array = [[], [], [], []]


func load_and_split(guaranteed: Dictionary = {}) -> void:
	var suspects := _load_json(json_path)

	if suspects.is_empty():
		push_error("SuspectLoader: failed to load or empty JSON")
		return
		
	# Normalize id to int for every suspect
	for s in suspects:
		s["id"] = int(s["id"])

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

	if not guaranteed.is_empty():
		_ensure_suspect_in_pool(suspects, guaranteed)

	var split := _random_split(suspects.size(), min_per_list, max_per_list)

	if split.is_empty():
		push_error("SuspectLoader: could not produce a valid split")
		return

	lists = [[], [], [], []]

	var cursor := 0

	for i in range(4):
		lists[i] = suspects.slice(cursor, cursor + split[i])
		cursor += split[i]

	if not guaranteed.is_empty():
		_ensure_suspect_in_lists(guaranteed)

	for i in range(4):
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


func get_list(index: int) -> Array:
	if index < 0 or index >= lists.size():
		push_error("SuspectLoader: invalid list index %d" % index)
		return []

	return lists[index]


func get_broker_list(broker: Broker) -> Array:
	return get_list(int(broker))


func _load_json(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("SuspectLoader: file not found: %s" % path)
		return []

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("SuspectLoader: cannot open file: %s" % path)
		return []

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)

	if typeof(parsed) != TYPE_ARRAY:
		push_error("SuspectLoader: JSON root must be an array")
		return []

	return parsed


func _ensure_suspect_in_pool(suspects: Array, guaranteed: Dictionary) -> void:
	var already_in := false

	for suspect in suspects:
		if str(suspect.get("id", "")) == str(guaranteed.get("id", "")):
			already_in = true
			break

	if already_in:
		return

	if suspects.is_empty():
		suspects.append(guaranteed)
		return

	suspects[randi() % suspects.size()] = guaranteed


func _ensure_suspect_in_lists(guaranteed: Dictionary) -> void:
	var found := false

	for i in range(lists.size()):
		for j in range(lists[i].size()):
			if str(lists[i][j].get("id", "")) == str(guaranteed.get("id", "")):
				found = true
				print(
					"Guaranteed suspect '%s' is in list %d at index %d"
					% [guaranteed.get("name", "-"), i, j]
				)
				break

		if found:
			break

	if found:
		return

	var available_lists := []

	for i in range(lists.size()):
		if not lists[i].is_empty():
			available_lists.append(i)

	if available_lists.is_empty():
		return

	var target_list: int = available_lists[randi() % available_lists.size()]
	var target_index: int = randi() % lists[target_list].size()

	lists[target_list][target_index] = guaranteed

	print(
		"Guaranteed suspect inserted into list %d at index %d"
		% [target_list, target_index]
	)


func _random_split(total: int, mins: Array, maxs: Array) -> Array:
	var min_sum := 0
	var max_sum := 0

	for i in range(4):
		min_sum += int(mins[i])
		max_sum += int(maxs[i])

	if total < min_sum or total > max_sum:
		push_error(
			"SuspectLoader: total=%d is outside feasible range [%d, %d]"
			% [total, min_sum, max_sum]
		)
		return []

	var sizes := mins.duplicate()
	var remaining := total - min_sum
	var headroom := []

	for i in range(4):
		headroom.append(int(maxs[i]) - int(mins[i]))

	while remaining > 0:
		var candidates := []

		for i in range(4):
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
# Kept Suspects
# ---------------------------------------------------------------------------------------------------

func can_add_kept_suspect() -> bool:
	return kept_suspects.size() < MAX_KEPT_SUSPECTS


func is_suspect_list_almost_full() -> bool:
	return kept_suspects.size() == MAX_KEPT_SUSPECTS - 1


func is_suspect_list_full() -> bool:
	return kept_suspects.size() >= MAX_KEPT_SUSPECTS


func add_kept_suspect(suspect: Dictionary) -> bool:
	if suspect.is_empty():
		print("Cannot add empty suspect")
		return false

	if is_suspect_list_full():
		print("Suspect List penuh")
		return false

	for saved in kept_suspects:
		if str(saved.get("id", "")) == str(suspect.get("id", "")):
			print("Suspect sudah ada")
			return false

	kept_suspects.append(suspect)
	return true


func remove_kept_suspect_by_id(id_value) -> void:
	for i in range(kept_suspects.size()):
		if str(kept_suspects[i].get("id", "")) == str(id_value):
			kept_suspects.remove_at(i)
			return


func clear_kept_suspects() -> void:
	kept_suspects.clear()
	selected_kept_suspect = {}


# ---------------------------------------------------------------------------------------------------
# ODP Reveal System
# ---------------------------------------------------------------------------------------------------

func reveal_field(field_name: String) -> void:
	if field_name in revealed_fields:
		return

	revealed_fields.append(field_name)


func is_field_revealed(field_name: String) -> bool:
	return field_name in revealed_fields


func clear_revealed_fields() -> void:
	revealed_fields.clear()


func check_reveal_from_kept(kept_data: Dictionary) -> void:
	if selected_suspect.is_empty() or kept_data.is_empty():
		return

	if kept_data.get("is_male", null) == selected_suspect.get("is_male", null):
		reveal_field("is_male")

	if kept_data.get("blood_type", "") == selected_suspect.get("blood_type", ""):
		reveal_field("blood_type")

	if abs(int(kept_data.get("age", 0)) - int(selected_suspect.get("age", 0))) <= 2:
		reveal_field("age")

	if abs(int(kept_data.get("height_cm", 0)) - int(selected_suspect.get("height_cm", 0))) <= 3:
		reveal_field("height_cm")

	if abs(int(kept_data.get("weight_kg", 0)) - int(selected_suspect.get("weight_kg", 0))) <= 5:
		reveal_field("weight_kg")


# ---------------------------------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------------------------------

func reset() -> void:
	selected_suspect = {}
	suspect_already_selected = false

	current_odp = {}
	kept_suspects.clear()
	selected_kept_suspect = {}

	revealed_fields.clear()

	lists = [[], [], [], []]

	tutorial_seen.clear()

	tutorials_completed = {
		"prolog": false,
		"suspect_menu": false,
		"stack_menu": false,
		"queue_orang_menu": false,
		"queue_fax_menu": false,
		"hashmap_menu": false,
		"choose_suspect_menu": false,
	}

	warning_flags = {
		"suspect_list_almost_full": false,
		"suspect_list_full": false
	}
