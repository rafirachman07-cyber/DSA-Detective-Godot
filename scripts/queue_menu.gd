extends Node2D

var icon_font = preload("res://assets/fonts/Thabit.ttf")

@onready var slot_1 = $Background/Board/Paper/Lorong/Slot1
@onready var slot_2 = $Background/Board/Paper/Lorong/Slot2
@onready var slot_3 = $Background/Board/Paper/Lorong/Slot3
@onready var slot_4 = $Background/Board/Paper/Lorong/Slot4
@onready var character_holder = $Background/Board/Paper/Lorong/CharacterHolder
@onready var suspect_image = $Background/Board/Paper/DataBox/image_suspect
@onready var mask = $Background/Board/Paper/Mask
@onready var kosong = $Background/Board/Paper/KosongLabel


@onready var peek_button = $Background/Board/Paper/PeekButton
@onready var pop_button = $Background/Board/Paper/PopButton
@onready var keep_button = $Background/Board/Paper/KeepButton
@onready var back_button = $Background/Board/Paper/BackButton

@onready var id_label = $Background/Board/Paper/DataBox/id_suspect
@onready var name_suspect_Label = $Background/Board/Paper/DataBox/nama_suspect_Label
@onready var name_label = $Background/Board/Paper/DataBox/nama_suspect
@onready var age_label = $Background/Board/Paper/DataBox/umur_suspect
@onready var gender_label = $Background/Board/Paper/DataBox/gender_suspect
@onready var height_label = $Background/Board/Paper/DataBox/tinggi_suspect
@onready var weight_label = $Background/Board/Paper/DataBox/berat_suspect
@onready var blood_label = $Background/Board/Paper/DataBox/goldar_suspect
@onready var enqueue_button = $Background/Board/Paper/EnqueueButton

var is_processing := false
var queue: Array = []
var people_data: Array = []


func _ready():
	randomize()
	
	gender_label.add_theme_font_override("font", icon_font)
	peek_button.pressed.connect(on_peek_pressed)
	pop_button.pressed.connect(on_pop_pressed)
	keep_button.pressed.connect(on_keep_pressed)
	back_button.pressed.connect(on_back_pressed)
	
	mask.visible = true
	enqueue_button.visible = false
	kosong.visible = false
	peek_button.visible = true
	pop_button.visible = false
	keep_button.visible = false

	load_people_data()
	create_queue(4)
	update_queue_positions()
	clear_data_box()


func load_people_data():
	var file := FileAccess.open("res://assets/characters/characters.json", FileAccess.READ)

	if file == null:
		push_error("Cannot open suspects.json")
		return

	var parsed = JSON.parse_string(file.get_as_text())

	if parsed == null:
		push_error("Invalid JSON")
		return

	people_data = parsed
	print("Loaded data: ", people_data.size())


func create_queue(amount: int):
	for i in amount:
		var character = create_character()
		character_holder.add_child(character)
		queue.append(character)


func create_character() -> Sprite2D:
	var sprite := Sprite2D.new()

	var paths := [
		"res://assets/characters/siluet/personDark.png",
		"res://assets/characters/siluet/personLight.png"
	]

	var path: String = paths.pick_random()
	var texture = load(path)

	if texture == null:
		push_error("Cannot load character: " + path)
		return sprite

	sprite.texture = texture
	sprite.scale = Vector2(0.90, 0.90)
	sprite.z_as_relative = false
	sprite.z_index = 100

	if not people_data.is_empty():
		sprite.set_meta("person_data", people_data.pick_random())

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


func on_peek_pressed():
	if is_processing or queue.is_empty():
		return
	
	
	peek_button.visible = false
	mask.visible = false
	pop_button.visible = true
	keep_button.visible = true

	peek_front_character()


func on_pop_pressed():
	if is_processing or queue.is_empty():
		return

	is_processing = true

	var front_character: Sprite2D = queue.pop_front()

	var exit_position := front_character.global_position + Vector2(500, 0)

	var tween := create_tween()
	tween.tween_property(
		front_character,
		"global_position",
		exit_position,
		0.5
	)

	await tween.finished
	front_character.queue_free()

	await move_queue_forward()

	is_processing = false

	if queue.is_empty():
		show_empty_queue_popup()
	else:
		peek_front_character()
		
func show_empty_queue_popup():
	clear_data_box()
	
	pop_button.disabled = true
	keep_button.disabled = true
	pop_button.visible = false
	keep_button.visible = false
	peek_button.visible = false

	kosong.visible = true
	
func on_keep_pressed():
	if is_processing or queue.is_empty():
		return

	is_processing = true

	var front_character: Sprite2D = queue.pop_front()
	queue.append(front_character)

	await move_queue_forward()

	is_processing = false
	peek_front_character()


func move_queue_forward():
	var slots = get_slots()
	var tween := create_tween()

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


func peek_front_character():
	if queue.is_empty():
		clear_data_box()
		pop_button.disabled = true
		keep_button.disabled = true
		return

	var front_character: Sprite2D = queue[0]

	if not front_character.has_meta("person_data"):
		push_error("Character has no data")
		return

	var data: Dictionary = front_character.get_meta("person_data")
	show_data_box(data)

	pop_button.disabled = false
	keep_button.disabled = false


func show_data_box(data: Dictionary):
	id_label.text = "%s" % str(data.get("id", "-"))
	name_suspect_Label.text = str(data.get("name", "-"))
	name_label.text = str(data.get("name", "-"))
	age_label.text = "%s" % str(data.get("age", "-"))
	gender_label.text = "%s" % get_gender_text(data.get("is_male", true))
	height_label.text = "%s cm" % str(data.get("height_cm", "-"))
	weight_label.text = "%s kg" % str(data.get("weight_kg", "-"))
	blood_label.text = "%s" % str(data.get("blood_type", "-"))

	load_suspect_image(str(data.get("sprite", "")))


func load_suspect_image(sprite_path: String):
	if sprite_path == "":
		suspect_image.texture = null
		return

	var fixed_path := sprite_path.replace("./", "res://assets/characters/")
	var texture = load(fixed_path)

	if texture == null:
		push_error("Cannot load suspect image: " + fixed_path)
		return

	suspect_image.texture = texture

func clear_data_box():
	id_label.text = ""
	name_label.text = ""
	age_label.text = ""
	gender_label.text = ""
	height_label.text = ""
	weight_label.text = ""
	blood_label.text = ""


func get_gender_text(is_male: bool) -> String:
	if is_male:
		return "♂"
	else:
		return "♀"


func on_back_pressed():
	get_tree().change_scene_to_file("res://scripts/suspect_menu.tscn")
