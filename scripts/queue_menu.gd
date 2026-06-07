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
@onready var meja = $Background/Board/Paper/Lorong/Meja
@onready var confirmation_tab = $ConfirmationTab
@onready var darkOverlay = $Background/darkOverlay

#Guide
@onready var guide_button = $Background/GuideButton
@onready var hint_page = $Background/GuideButton/hintPage
@onready var operation_1 = $Background/GuideButton/hintPage/operation_1
@onready var operation_2 = $Background/GuideButton/hintPage/operation_2
@onready var operation_3 = $Background/GuideButton/hintPage/operation_3
@onready var operation_4 = $Background/GuideButton/hintPage/operation_4
@onready var close_button = $Background/GuideButton/hintPage/close_button

@onready var peek_button = $Background/Board/Paper/PeekButton
@onready var pop_button = $Background/Board/Paper/PopButton
@onready var keep_button = $Background/Board/Paper/KeepButton
@onready var enqueue_button = $Background/Board/Paper/EnqueueButton
@onready var back_button = $Background/Board/Paper/BackButton

#ODP Button
@onready var odp_preview = $ODPPreviewPanel
@onready var odp_button = $Background/Board/Paper/ODPButton

@onready var id_label = $Background/Board/Paper/DataBox/id_suspect
@onready var name_suspect_Label = $Background/Board/Paper/DataBox/nama_suspect_Label
@onready var name_label = $Background/Board/Paper/DataBox/nama_suspect
@onready var age_label = $Background/Board/Paper/DataBox/umur_suspect
@onready var gender_label = $Background/Board/Paper/DataBox/gender_suspect
@onready var height_label = $Background/Board/Paper/DataBox/tinggi_suspect
@onready var weight_label = $Background/Board/Paper/DataBox/berat_suspect
@onready var blood_label = $Background/Board/Paper/DataBox/goldar_suspect
@onready var dialogue_box = $DialogBox

var is_processing := false
var queue: Array = []
var people_data: Array = []

var pending_action: Callable = Callable()
var dialogue_step := "none"


func _ready():
	randomize()

	meja.z_as_relative = false
	meja.z_index = 200
	character_holder.z_as_relative = false
	character_holder.z_index = 50

	gender_label.add_theme_font_override("font", icon_font)

	if not dialogue_box.dialogue_finished.is_connected(_on_tutorial_selesai):
		dialogue_box.dialogue_finished.connect(_on_tutorial_selesai)
	
	#ODP
	odp_button.mouse_entered.connect(_show_odp)
	odp_button.mouse_exited.connect(_hide_odp)
	
	# Guide
	guide_button.pressed.connect(on_guide_pressed)
	close_button.pressed.connect(on_close_pressed)
	guide_button.visible = true
	hint_page.visible = false
	operation_1.visible = false
	operation_2.visible = false
	operation_3.visible = false
	operation_4.visible = false
	close_button.visible = false
	
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
	await create_queue_with_animation(4, false)
	clear_data_box()

	if not GlobalData.is_tutorial_completed("queue_orang_menu"):
		dialogue_step = "queue_intro"
		dialogue_box.start_dialogue("queue_orang_menu", "on_first_enter")
	else:
		dialogue_box.hide()


func _on_tutorial_selesai():
	if dialogue_step == "queue_intro":
		GlobalData.mark_tutorial_completed("queue_orang_menu")
		dialogue_step = "none"

	elif dialogue_step == "queue_peek":
		GlobalData.mark_tutorial_seen("queue_peek")
		dialogue_step = "none"
		_run_pending_action()

	elif dialogue_step == "queue_dequeue":
		GlobalData.mark_tutorial_seen("queue_dequeue")
		dialogue_step = "none"
		_run_pending_action()

	elif dialogue_step == "queue_keep":
		GlobalData.mark_tutorial_seen("queue_keep")
		dialogue_step = "none"
		_run_pending_action()

	elif dialogue_step == "queue_empty":
		GlobalData.mark_tutorial_seen("queue_empty")
		dialogue_step = "none"

	elif dialogue_step == "queue_enqueue":
		GlobalData.mark_tutorial_seen("queue_enqueue")
		dialogue_step = "none"
		_run_pending_action()


func _run_pending_action():
	if pending_action.is_valid():
		pending_action.call()
	pending_action = Callable()

func take_random_person() -> Dictionary:
	if people_data.is_empty():
		return {}

	var index := randi_range(0, people_data.size() - 1)
	var person: Dictionary = people_data[index]

	people_data.remove_at(index)
	GlobalData.lists[GlobalData.Broker.QUEUE] = people_data

	return person

func load_people_data():
	people_data = GlobalData.get_list(GlobalData.Broker.QUEUE)
	print("Loaded queue data: ", people_data.size())

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


func get_slots() -> Array:
	return [slot_1, slot_2, slot_3, slot_4]


func get_silhouette_path(index: int) -> String:
	if index % 2 == 0:
		return "res://assets/characters/siluet/personDark.png"
	return "res://assets/characters/siluet/personLight.png"


func get_person_data() -> Dictionary:
	if people_data.is_empty():
		return {}

	return people_data.pick_random()

#ODP
func _show_odp():
	odp_preview.open()

func _hide_odp():
	odp_preview.close()
	
#Guide
func on_guide_pressed():
	guide_button.visible = true
	hint_page.visible = true
	operation_1.visible = true
	operation_2.visible = true
	operation_3.visible = true
	operation_4.visible = true
	close_button.visible = true
	
func on_close_pressed():
	guide_button.visible = false
	hint_page.visible = false
	operation_1.visible = false
	operation_2.visible = false
	operation_3.visible = false
	operation_4.visible = false
	close_button.visible = false
	
func create_character_from_data(data: Dictionary, index: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	var texture = load(get_silhouette_path(index))

	if texture == null:
		push_error("Cannot load silhouette")
		return sprite

	sprite.texture = texture
	sprite.scale = Vector2(0.90, 0.90)
	sprite.modulate.a = 1.0
	sprite.z_as_relative = false
	sprite.z_index = 10

	if not data.is_empty():
		sprite.set_meta("person_data", data)

	return sprite


func create_queue_with_animation(amount: int, animated: bool):
	is_processing = true

	for child in character_holder.get_children():
		child.queue_free()

	queue.clear()

	for i in range(amount):
		var data := take_random_person()
		var character := create_character_from_data(data, i)
		character_holder.add_child(character)
		queue.append(character)

		var target_slot = get_slots()[i]
		var target_pos = target_slot.global_position
		var target_scale = target_slot.scale

		if animated:
			character.global_position = slot_4.global_position + Vector2(0, -160)
			character.scale = target_scale * 0.65
			character.modulate.a = 0.0

			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(character, "global_position", target_pos, 0.45)
			tween.tween_property(character, "scale", target_scale, 0.45)
			tween.tween_property(character, "modulate:a", 1.0, 0.25)
			await tween.finished
		else:
			character.global_position = target_pos
			character.scale = target_scale

		update_queue_positions()
		await get_tree().create_timer(0.08).timeout

	is_processing = false
	update_front_rear_labels()


func update_queue_positions():
	var slots = get_slots()

	for i in range(queue.size()):
		var character: Sprite2D = queue[i]
		character.global_position = slots[i].global_position
		character.scale = slots[i].scale
		character.z_index = 100 - i
		character.modulate.a = 1.0

	update_front_rear_labels()


func update_front_rear_labels():
	if queue.is_empty():
		front_label.visible = false
		rear_label.visible = false
		return

	front_label.visible = true
	rear_label.visible = true

	var front_character: Sprite2D = queue[0]
	var rear_character: Sprite2D = queue[queue.size() - 1]

	front_label.global_position = front_character.global_position + Vector2(-160, -10)
	rear_label.global_position = rear_character.global_position + Vector2(110, -20)


func on_peek_pressed():
	if is_processing or queue.is_empty():
		return

	if not GlobalData.has_seen_tutorial("queue_peek"):
		dialogue_step = "queue_peek"
		pending_action = Callable(self, "_do_peek")
		dialogue_box.start_dialogue("queue_orang_menu", "on_peek_first_pressed")
		return

	_do_peek()


func _do_peek():
	peek_button.visible = false
	mask.visible = false
	pop_button.visible = true
	keep_button.visible = true
	peek_front_character()


func on_pop_pressed():
	if is_processing or queue.is_empty():
		return

	if not GlobalData.has_seen_tutorial("queue_dequeue"):
		dialogue_step = "queue_dequeue"
		pending_action = Callable(self, "_do_dequeue")
		dialogue_box.start_dialogue("queue_orang_menu", "on_dequeue_first_pressed")
		return

	_do_dequeue()


func _do_dequeue():
	process_and_remove_front()


func on_keep_pressed():
	if is_processing or queue.is_empty():
		return

	if not GlobalData.has_seen_tutorial("queue_keep"):
		dialogue_step = "queue_keep"
		pending_action = Callable(self, "_do_keep")
		dialogue_box.start_dialogue("queue_orang_menu", "on_keep_first_pressed")
		return

	_do_keep()


func _do_keep():
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
	tween.tween_property(front_character, "global_position", front_character.global_position + Vector2(120, 0), 0.3)
	tween.tween_property(front_character, "modulate:a", 0.0, 0.3)

	await tween.finished
	front_character.queue_free()

	if queue.is_empty():
		is_processing = false
		show_empty_queue_popup()
		return

	await move_queue_forward()

	is_processing = false
	peek_front_character()


func move_queue_forward():
	var slots = get_slots()
	var tween := create_tween()

	for i in range(queue.size()):
		var character: Sprite2D = queue[i]
		character.z_index = 100 - i
		character.modulate.a = 1.0

		tween.parallel().tween_property(character, "global_position", slots[i].global_position, 0.5)
		tween.parallel().tween_property(character, "scale", slots[i].scale, 0.5)

	await tween.finished
	update_front_rear_labels()


func show_empty_queue_popup():
	clear_data_box()

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

	update_front_rear_labels()

	if not GlobalData.has_seen_tutorial("queue_empty"):
		dialogue_step = "queue_empty"
		GlobalData.mark_tutorial_seen("queue_empty")
		dialogue_box.start_dialogue("queue_orang_menu", "on_queue_empty")


func on_enqueue_pressed():
	if is_processing:
		return

	if not GlobalData.has_seen_tutorial("queue_enqueue"):
		dialogue_step = "queue_enqueue"
		pending_action = Callable(self, "_do_enqueue")
		dialogue_box.start_dialogue("queue_orang_menu", "on_enqueue_button_appears")
		return

	_do_enqueue()


func _do_enqueue():
	enqueue()


func enqueue():
	if not queue.is_empty():
		return

	if people_data.is_empty():
		show_empty_queue_popup()
		return

	reset_ui_to_start()
	clear_data_box()

	await create_queue_with_animation(4, true)

	if queue.is_empty():
		show_empty_queue_popup()

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
	id_label.text = str(data.get("id", "-"))
	name_suspect_Label.text = str(data.get("name", "-"))
	name_label.text = str(data.get("name", "-"))
	age_label.text = str(data.get("age", "-"))
	gender_label.text = get_gender_text(data.get("is_male", true))
	height_label.text = "%s cm" % str(data.get("height_cm", "-"))
	weight_label.text = "%s kg" % str(data.get("weight_kg", "-"))
	blood_label.text = str(data.get("blood_type", "-"))

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
	return "♂" if is_male else "♀"


func on_keep_confirmed(data: Dictionary):
	darkOverlay.visible = false

	var success: bool = GlobalData.add_kept_suspect(data)

	# Kalau gagal tambah karena penuh / duplikat
	if not success:
		if GlobalData.is_suspect_list_full():
			dialogue_box.start_dialogue(
				"global_alerts",
				"suspect_list_full"
			)

		pop_button.disabled = false
		keep_button.disabled = false
		return

	# Kalau berhasil keep
	GlobalData.check_reveal_from_kept(data)

	# Kalau sudah 5/6
	if GlobalData.kept_suspects.size() == 5:
		dialogue_box.start_dialogue(
			"global_alerts",
			"suspect_list_almost_full"
		)

	process_and_remove_front()


func on_keep_cancelled():
	darkOverlay.visible = false
	pop_button.disabled = false
	keep_button.disabled = false


func on_back_pressed():
	get_tree().change_scene_to_file("res://scripts/suspect_menu.tscn")
