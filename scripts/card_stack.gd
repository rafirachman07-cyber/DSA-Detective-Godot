extends Control

const STACK_OFFSET = Vector2(6, 6)
const MAX_BEHIND = 3

var card_scene = preload("res://scripts/paper.tscn")
var card_size = Vector2.ZERO
var data = []

func _ready() -> void:
	# read the actual card size from an instance
	var temp = card_scene.instantiate()
	add_child(temp)
	await get_tree().process_frame  # wait one frame for layout to resolve
	card_size = temp.size
	temp.queue_free()

	# test data — replace this later with real data
	set_data(["Item 1", "Item 2", "Item 3"])

func set_data(new_data: Array) -> void:
	data = new_data
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	if data.is_empty():
		return

	var visible_count = min(data.size(), MAX_BEHIND + 1)
	var total_offset = STACK_OFFSET * (visible_count - 1)
	var stack_size = card_size + total_offset

	var origin = (size - stack_size) / 2.0

	for i in range(visible_count - 1, -1, -1):
		var card = card_scene.instantiate()
		add_child(card)

		var depth = visible_count - 1 - i
		card.position = origin + (STACK_OFFSET * depth)
		card.z_index = i

		if i == 0:
			card.setup(data[0])
		else:
			card.setup(null)
