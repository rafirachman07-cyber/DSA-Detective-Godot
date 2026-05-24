extends Node2D

@onready var slot_1 = $Background/Board/Paper/Lorong/Slot1
@onready var slot_2 = $Background/Board/Paper/Lorong/Slot2
@onready var slot_3 = $Background/Board/Paper/Lorong/Slot3
@onready var slot_4 = $Background/Board/Paper/Lorong/Slot4
@onready var character_holder = $Background/Board/Paper/Lorong/CharacterHolder
@onready var keep_button = $Background/Board/Paper/KeepButton
@onready var pass_button = $Background/Board/Paper/PassButton

var is_processing := false
var suspects: Array = []
var queue: Array = []

func _ready():
	print("KeepButton:", keep_button)
	print("PassButton:", pass_button)

	keep_button.pressed.connect(Callable(self, "process_current_character"))
	pass_button.pressed.connect(Callable(self, "process_current_character"))
	randomize()
	
	create_queue(4)
	update_queue_positions()

func create_queue(amount: int):
	for i in amount:
		var character = create_character()
		character_holder.add_child(character)

		queue.append(character)


func create_character() -> Sprite2D:
	var sprite := Sprite2D.new()

	var random_id := randi_range(1, 150)
	var path := "res://assets/characters/output3/%d.png" % random_id

	print("Loading character: ", path)

	var texture = load(path)

	if texture == null:
		push_error("Cannot load character: " + path)
		return sprite
	
	sprite.z_as_relative = false
	sprite.z_index = 100
	sprite.texture = texture
	sprite.scale = Vector2(0.5, 0.5)

	return sprite


func get_slots() -> Array:
	return [
		slot_1.global_position,
		slot_2.global_position,
		slot_3.global_position,
		slot_4.global_position
	]


func update_queue_positions():
	var slots = get_slots()

	for i in queue.size():
		var character: Sprite2D = queue[i]
		character.global_position = slots[i]
		character.z_index = 100 - i
		
func process_current_character():
	if is_processing:
		return

	is_processing = true

	var current_node: Sprite2D = queue.pop_front()

	queue.append(current_node)

	move_queue_forward()
	
func add_new_character():
	var character = create_character()
	character_holder.add_child(character)

	character.global_position = slot_3.global_position + Vector2(-300, 0)

	queue.append(character)

func move_queue_forward():
	var slots = get_slots()

	var tween = create_tween()

	for i in queue.size():
		var character: Sprite2D = queue[i]

		character.z_index = 100 - i

		tween.parallel().tween_property(
			character,
			"global_position",
			slots[i],
			0.5
		)

	await tween.finished

	is_processing = false
