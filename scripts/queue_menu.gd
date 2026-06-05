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
@onready var front_label = $Background/Board/Paper/Lorong/Front
@onready var rear_label = $Background/Board/Paper/Lorong/Rear

#Confirm Box
@onready var meja = $Background/Board/Paper/Lorong/Meja
@onready var confirmation_tab = $ConfirmationTab
@onready var batalkanButton = $KeepConfirmPanel/BatalkanButton
@onready var setujuButton = $KeepConfirmPanel/SetujuButton
@onready var darkOverlay = $Background/darkOverlay

#main page
@onready var peek_button = $Background/Board/Paper/PeekButton
@onready var pop_button = $Background/Board/Paper/PopButton
@onready var keep_button = $Background/Board/Paper/KeepButton
@onready var enqueue_button = $Background/Board/Paper/EnqueueButton
@onready var back_button = $Background/Board/Paper/BackButton

@onready var id_label = $Background/Board/Paper/DataBox/id_suspect
@onready var name_suspect_Label = $Background/Board/Paper/DataBox/nama_suspect_Label
@onready var name_label = $Background/Board/Paper/DataBox/nama_suspect
@onready var age_label = $Background/Board/Paper/DataBox/umur_suspect
@onready var gender_label = $Background/Board/Paper/DataBox/gender_suspect
@onready var height_label = $Background/Board/Paper/DataBox/tinggi_suspect
@onready var weight_label = $Background/Board/Paper/DataBox/berat_suspect
@onready var blood_label = $Background/Board/Paper/DataBox/goldar_suspect


var is_processing := false
var queue: Array = []
var people_data: Array = []


func _ready():
	randomize()
	
	meja.z_as_relative = false
	meja.z_index = 200
	character_holder.z_as_relative = false
	character_holder.z_index = 50
	gender_label.add_theme_font_override("font", icon_font)
	#batalkanButton.pressed.connect(on_cancel_keep_pressed)
	#setujuButton.pressed.connect(on_confirm_keep_pressed)
	peek_button.pressed.connect(on_peek_pressed)
	pop_button.pressed.connect(on_pop_pressed)
	keep_button.pressed.connect(on_keep_pressed)
	enqueue_button.pressed.connect(on_enqueue_pressed)
	back_button.pressed.connect(on_back_pressed)
	confirmation_tab.confirmed.connect(on_keep_confirmed)
	confirmation_tab.cancelled.connect(on_keep_cancelled)
	
	darkOverlay.color = Color(0, 0, 0, 0.55)
	darkOverlay.visible = false
	darkOverlay.z_index = 900
	load_people_data()

	reset_ui_to_start()
	create_queue(4)
	update_queue_positions()
	clear_data_box()

func on_keep_confirmed(data: Dictionary):
	darkOverlay.visible = false

	if not GlobalData.kept_suspects.has(data):
		GlobalData.kept_suspects.append(data)

	process_and_remove_front()

func on_keep_cancelled():
	darkOverlay.visible = false

	pop_button.disabled = false
	keep_button.disabled = false

func update_front_rear_labels():
	if queue.is_empty():
		front_label.visible = false
		rear_label.visible = false
		return

	front_label.visible = true
	rear_label.visible = true

	var front_character: Sprite2D = queue[0]
	var rear_character: Sprite2D = queue[queue.size() - 1]

	front_label.global_position = front_character.global_position + Vector2(-230, -50)
	rear_label.global_position = rear_character.global_position + Vector2(100, -20)
		
func reset_ui_to_start():
	is_processing = false

	mask.visible = true
	kosong.visible = false

	peek_button.visible = true
	pop_button.visible = false
	keep_button.visible = false
	enqueue_button.visible = false

	peek_button.disabled = false
	pop_button.disabled = false
	keep_button.disabled = false
	enqueue_button.disabled = false


func load_people_data():
	var file := FileAccess.open("res://assets/characters/characters.json", FileAccess.READ)

	if file == null:
		push_error("Cannot open characters.json")
		return

	var parsed = JSON.parse_string(file.get_as_text())

	if parsed == null:
		push_error("Invalid JSON")
		return

	people_data = parsed
	print("Loaded data: ", people_data.size())


func create_queue(amount: int):
	for i in range(amount):
		var character := create_character(i)
		character_holder.add_child(character)
		queue.append(character)
	update_front_rear_labels()

func create_character(index: int) -> Sprite2D:
	var sprite := Sprite2D.new()

	var path := get_silhouette_path(index)
	var texture = load(path)

	if texture == null:
		push_error("Cannot load character: " + path)
		return sprite

	sprite.texture = texture
	sprite.scale = Vector2(0.90, 0.90)
	sprite.modulate.a = 1.0
	sprite.z_as_relative = false
	sprite.z_index = 10

	if not people_data.is_empty():
		sprite.set_meta("person_data", people_data.pick_random())

	return sprite


func get_silhouette_path(index: int) -> String:
	if index % 2 == 0:
		return "res://assets/characters/siluet/personDark.png"
	else:
		return "res://assets/characters/siluet/personLight.png"


func get_slots() -> Array:
	return [
		slot_1.global_position,
		slot_2.global_position,
		slot_3.global_position,
		slot_4.global_position
	]


func update_queue_positions():
	var slots = get_slots()

	for i in range(queue.size()):
		var character: Sprite2D = queue[i]
		character.global_position = slots[i]
		character.z_index = 100 - i
		character.modulate.a = 1.0
	update_front_rear_labels()


func on_peek_pressed():
	if is_processing or queue.is_empty():
		return

	peek_button.visible = false
	mask.visible = false
	pop_button.visible = true
	keep_button.visible = true

	peek_front_character()


func on_pop_pressed():
	process_and_remove_front()



func on_keep_pressed():
	if is_processing or queue.is_empty():
		return

	var front_character: Sprite2D = queue[0]

	if not front_character.has_meta("person_data"):
		return

	var queue_person: Dictionary = front_character.get_meta("person_data")
	var odp_person: Dictionary = GlobalData.selected_suspect

	pop_button.disabled = true
	keep_button.disabled = true

	darkOverlay.visible = true
	confirmation_tab.open(odp_person, queue_person)


	
func process_and_remove_front():
	if is_processing or queue.is_empty():
		return

	is_processing = true

	var front_character: Sprite2D = queue.pop_front()

	var tween := create_tween()
	tween.set_parallel(true)

	# Geser sedikit saja, lalu hilang.
	tween.tween_property(
		front_character,
		"global_position",
		front_character.global_position + Vector2(120, 0),
		0.3
	)

	tween.tween_property(
		front_character,
		"modulate:a",
		0.0,
		0.3
	)

	await tween.finished
	front_character.queue_free()

	if queue.is_empty():
		is_processing = false
		show_empty_queue_popup()
		return

	await move_queue_forward()

	is_processing = false
	peek_front_character()
	update_front_rear_labels()

func move_queue_forward():
	var slots = get_slots()
	var tween := create_tween()

	for i in range(queue.size()):
		var character: Sprite2D = queue[i]
		character.z_index = 100 - i
		character.modulate.a = 1.0

		tween.parallel().tween_property(
			character,
			"global_position",
			slots[i],
			0.5
		)

	await tween.finished
	update_front_rear_labels()

func show_empty_queue_popup():
	clear_data_box()
	suspect_image.texture = null

	mask.visible = false
	kosong.text = "ANTRIAN HABIS"
	kosong.visible = true
	kosong.z_index = 999

	peek_button.visible = false
	pop_button.visible = false
	keep_button.visible = false

	peek_button.disabled = true
	pop_button.disabled = true
	keep_button.disabled = true

	enqueue_button.visible = true
	enqueue_button.disabled = false
	enqueue_button.z_index = 999


func on_enqueue_pressed():
	if is_processing:
		return

	enqueue()


func enqueue():
	if not queue.is_empty():
		print("Queue still has: ", queue.size())
		return

	for child in character_holder.get_children():
		child.queue_free()

	queue.clear()

	create_queue(4)
	update_queue_positions()
	reset_ui_to_start()
	clear_data_box()
	update_front_rear_labels()

func peek_front_character():
	if queue.is_empty():
		show_empty_queue_popup()
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
	name_suspect_Label.text = ""
	name_label.text = ""
	age_label.text = ""
	gender_label.text = ""
	height_label.text = ""
	weight_label.text = ""
	blood_label.text = ""
	suspect_image.texture = null


func get_gender_text(is_male: bool) -> String:
	if is_male:
		return "♂"
	else:
		return "♀"


func on_back_pressed():
	get_tree().change_scene_to_file("res://scripts/suspect_menu.tscn")
