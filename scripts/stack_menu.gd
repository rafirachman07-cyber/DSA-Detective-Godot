extends Node2D

var icon_font = preload("res://assets/fonts/Thabit.ttf")

@onready var suspect_image = $Background/Board/Paper/DataBox/image_suspect
@onready var mask = $Background/Board/Paper/Mask
@onready var kosong = $Background/Board/Paper/KosongLabel

@onready var peek_button = $Background/Board/Paper/PeekButton
@onready var pop_button = $Background/Board/Paper/PopButton
@onready var keep_button = $Background/Board/Paper/KeepButton
@onready var back_button = $Background/Board/Paper/BackButton
@onready var push_button = $Background/Board/Paper/PushButton

@onready var id_label = $Background/Board/Paper/DataBox/id_suspect
@onready var name_suspect_Label = $Background/Board/Paper/DataBox/nama_suspect_Label
@onready var name_label = $Background/Board/Paper/DataBox/nama_suspect
@onready var age_label = $Background/Board/Paper/DataBox/umur_suspect
@onready var gender_label = $Background/Board/Paper/DataBox/gender_suspect
@onready var height_label = $Background/Board/Paper/DataBox/tinggi_suspect
@onready var weight_label = $Background/Board/Paper/DataBox/berat_suspect
@onready var blood_label = $Background/Board/Paper/DataBox/goldar_suspect

#ODP Button
@onready var odp_preview = $ODPPreviewPanel
@onready var odp_button = $Background/Board/Paper/ODPButton

#Guide
@onready var guide_button = $Background/GuideButton
@onready var hint_page = $Background/GuideButton/hintPage
@onready var operation_1 = $Background/GuideButton/hintPage/operation_1
@onready var operation_2 = $Background/GuideButton/hintPage/operation_2
@onready var operation_3 = $Background/GuideButton/hintPage/operation_3
@onready var operation_4 = $Background/GuideButton/hintPage/operation_4
@onready var close_button = $Background/GuideButton/hintPage/close_button

@onready var confirmation_tab = $ConfirmationTab
@onready var darkOverlay = $Background/darkOverlay
@onready var card_stack_control = $Background/Board/Paper/Bg/CardStack
@onready var dialogue_box = $DialogBox

const STACK_OFFSET = Vector2(-30, 0)
const MAX_BEHIND = 6
const ONE_LOOP_COUNT = 8

var card_scene = preload("res://scripts/paper.tscn")
var card_size := Vector2.ZERO

var is_processing := false
var people_data = []
var current_loop_data = []
var current_loop_count = ONE_LOOP_COUNT

var pending_action: Callable = Callable()
var dialogue_step := "none"


func _ready():
	randomize()

	if not dialogue_box.dialogue_finished.is_connected(_on_tutorial_selesai):
		dialogue_box.dialogue_finished.connect(_on_tutorial_selesai)

	gender_label.add_theme_font_override("font", icon_font)

	peek_button.pressed.connect(on_peek_pressed)
	pop_button.pressed.connect(on_pop_pressed)
	keep_button.pressed.connect(on_keep_pressed)
	back_button.pressed.connect(on_back_pressed)
	push_button.pressed.connect(on_push_pressed)
	
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

	confirmation_tab.confirmed.connect(on_keep_confirmed)
	confirmation_tab.cancelled.connect(on_keep_cancelled)

	darkOverlay.color = Color(0, 0, 0, 0.55)
	darkOverlay.visible = false
	darkOverlay.z_index = 900

	reset_ui_to_start()

	load_people_data()
	
	if GlobalData.curr_stack_data.is_empty():
		GlobalData.curr_stack_data = pick_and_pop()
	
	current_loop_data = GlobalData.curr_stack_data

	var temp = card_scene.instantiate()
	card_stack_control.add_child(temp)
	await get_tree().process_frame
	card_size = temp.size
	temp.queue_free()

	rebuild_stack()
	clear_data_box()

	if not GlobalData.is_tutorial_completed("stack_menu"):
		dialogue_step = "stack_menu_intro"
		dialogue_box.start_dialogue("stack_menu", "on_first_enter")
	else:
		dialogue_box.hide()

#ODP
func _show_odp():
	odp_preview.open()

func _hide_odp():
	odp_preview.close()

func _on_tutorial_selesai():
	if dialogue_step == "stack_menu_intro":
		GlobalData.mark_tutorial_completed("stack_menu")
		dialogue_step = "none"

	elif dialogue_step == "stack_peek":
		GlobalData.mark_tutorial_seen("stack_peek")
		dialogue_step = "none"
		_run_pending_action()

	elif dialogue_step == "stack_pop":
		GlobalData.mark_tutorial_seen("stack_pop")
		dialogue_step = "none"
		_run_pending_action()

	elif dialogue_step == "stack_keep":
		GlobalData.mark_tutorial_seen("stack_keep")
		dialogue_step = "none"
		_run_pending_action()

	elif dialogue_step == "stack_push":
		GlobalData.mark_tutorial_seen("stack_push")
		dialogue_step = "none"
		_run_pending_action()

	elif dialogue_step == "stack_empty":
		GlobalData.mark_tutorial_seen("stack_empty")
		dialogue_step = "none"


func _run_pending_action():
	if pending_action.is_valid():
		pending_action.call()
	pending_action = Callable()


func load_people_data():
	people_data = GlobalData.get_list(GlobalData.Broker.STACK)
	print("Loaded stack data: ", people_data.size())


func pick_and_pop() -> Array:
	var picked := people_data.slice(0, ONE_LOOP_COUNT)
	people_data = people_data.slice(ONE_LOOP_COUNT)

	GlobalData.lists[GlobalData.Broker.STACK] = people_data

	return picked

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


func rebuild_stack():
	for child in card_stack_control.get_children():
		child.queue_free()

	if current_loop_data.is_empty():
		return

	var visible_count = min(current_loop_data.size(), MAX_BEHIND + 1)
	var total_spread = abs(STACK_OFFSET.x) * (visible_count - 1)
	var stack_width = card_size.x + total_spread
	var stack_height = card_size.y

	var origin_x = (card_stack_control.size.x - stack_width) / 2.0
	var origin_y = (card_stack_control.size.y - stack_height) / 2.0
	var front_x = origin_x + total_spread
	var front_y = origin_y

	var throw_start_x = card_stack_control.size.x + 500.0

	for i in range(visible_count):
		var card = card_scene.instantiate()
		card_stack_control.add_child(card)

		var depth = visible_count - 1 - i
		var target_pos = Vector2(front_x - abs(STACK_OFFSET.x) * depth, front_y)

		card.position = Vector2(throw_start_x, front_y)
		card.z_index = i

		if i == visible_count - 1:
			card.setup(current_loop_data.back())
		else:
			card.setup(null)

		var delay = i * 0.08

		var tween = create_tween()
		tween.tween_interval(delay)
		tween.tween_property(card, "position", target_pos, 0.35)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_BACK)


func on_peek_pressed():
	if is_processing or current_loop_data.is_empty():
		return

	if not GlobalData.has_seen_tutorial("stack_peek"):
		dialogue_step = "stack_peek"
		pending_action = Callable(self, "_do_peek")
		dialogue_box.start_dialogue("stack_menu", "on_peek_first_pressed")
		return

	_do_peek()


func _do_peek():
	peek_button.visible = false
	mask.visible = false
	pop_button.visible = true
	keep_button.visible = true

	peek_front()


func on_pop_pressed():
	if is_processing or current_loop_data.is_empty() or current_loop_count <= 0:
		return

	if not GlobalData.has_seen_tutorial("stack_pop"):
		dialogue_step = "stack_pop"
		pending_action = Callable(self, "_do_pop")
		dialogue_box.start_dialogue("stack_menu", "on_pop_first_pressed")
		return

	_do_pop()


func _do_pop():
	if is_processing or current_loop_data.is_empty() or current_loop_count <= 0:
		return

	is_processing = true

	var all_children = card_stack_control.get_children()

	if all_children.is_empty():
		is_processing = false
		show_empty_state()
		return

	var top_card = all_children.back()
	var remaining_children = all_children.slice(0, all_children.size() - 1)

	var exit_y = card_stack_control.size.y + 40.0
	var tween = create_tween()

	tween.tween_property(top_card, "position:y", exit_y, 0.3)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_BACK)

	await tween.finished

	top_card.queue_free()
	current_loop_data.pop_back()
	current_loop_count -= 1

	if current_loop_data.is_empty() or current_loop_count <= 0:
		is_processing = false
		show_empty_state()
		return

	var visible_count = min(current_loop_data.size(), MAX_BEHIND + 1)
	var total_spread = abs(STACK_OFFSET.x) * (visible_count - 1)
	var stack_width = card_size.x + total_spread
	var origin_x = (card_stack_control.size.x - stack_width) / 2.0
	var origin_y = (card_stack_control.size.y - card_size.y) / 2.0
	var front_x = origin_x + total_spread

	if current_loop_data.size() > remaining_children.size():
		var new_card = card_scene.instantiate()
		card_stack_control.add_child(new_card)
		card_stack_control.move_child(new_card, 0)
		new_card.setup(null)
		new_card.z_index = 0

		var back_depth = visible_count - 1
		var back_pos = Vector2(front_x - abs(STACK_OFFSET.x) * back_depth, origin_y)
		new_card.position = back_pos

	var reveal_tween = create_tween()
	var existing = card_stack_control.get_children()

	for i in range(1, existing.size()):
		var current_pos = existing[i].position
		reveal_tween.parallel().tween_property(
			existing[i],
			"position",
			current_pos + Vector2(abs(STACK_OFFSET.x), 0),
			0.15
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

	await reveal_tween.finished

	var shift_tween = create_tween()
	var all_cards = card_stack_control.get_children()

	for i in range(all_cards.size()):
		var depth = all_cards.size() - 1 - i
		var target_pos = Vector2(front_x - abs(STACK_OFFSET.x) * depth, origin_y)

		shift_tween.parallel().tween_property(
			all_cards[i],
			"position",
			target_pos,
			0.25
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)

		all_cards[i].z_index = i

	await shift_tween.finished

	is_processing = false
	peek_front()


func on_keep_pressed():
	if is_processing or current_loop_data.is_empty():
		return

	if not GlobalData.has_seen_tutorial("stack_keep"):
		dialogue_step = "stack_keep"
		pending_action = Callable(self, "_do_keep")
		dialogue_box.start_dialogue("stack_menu", "on_keep_first_pressed")
		return

	_do_keep()


func _do_keep():
	if is_processing or current_loop_data.is_empty():
		return

	var selected_person: Dictionary = current_loop_data.back()
	var odp_person: Dictionary = GlobalData.selected_suspect

	pop_button.disabled = true
	keep_button.disabled = true

	darkOverlay.visible = true
	confirmation_tab.open(odp_person, selected_person)


func peek_front():
	if current_loop_data.is_empty():
		clear_data_box()
		pop_button.disabled = true
		keep_button.disabled = true
		return

	var data: Dictionary = current_loop_data.back()
	show_data_box(data)

	pop_button.disabled = false
	keep_button.disabled = false


func show_empty_state():
	clear_data_box()

	pop_button.visible = false
	keep_button.visible = false
	peek_button.visible = false
	push_button.visible = true

	kosong.text = "HABIS"
	kosong.visible = true

	if not GlobalData.has_seen_tutorial("stack_empty"):
		dialogue_step = "stack_empty"
		GlobalData.mark_tutorial_seen("stack_empty")
		dialogue_box.start_dialogue("stack_menu", "on_stack_empty")


func on_push_pressed():
	if people_data.is_empty() and current_loop_data.is_empty():
		print("No more data on stack")
		return

	if not GlobalData.has_seen_tutorial("stack_push"):
		dialogue_step = "stack_push"
		pending_action = Callable(self, "_do_push")
		dialogue_box.start_dialogue("stack_menu", "on_push_button_appears")
		return

	_do_push()


func _do_push():
	if people_data.is_empty() and current_loop_data.is_empty():
		print("No more data on stack")
		return

	current_loop_data = pick_and_pop()
	current_loop_count = ONE_LOOP_COUNT

	reset_ui_to_start()
	rebuild_stack()
	clear_data_box()


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


func reset_ui_to_start():
	is_processing = false

	mask.visible = true
	kosong.visible = false

	peek_button.visible = true
	pop_button.visible = false
	keep_button.visible = false
	push_button.visible = false

	peek_button.disabled = false
	pop_button.disabled = false
	keep_button.disabled = false
	push_button.disabled = false


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


func on_back_pressed():
	get_tree().change_scene_to_file("res://scripts/suspect_menu.tscn")

func on_keep_confirmed(data: Dictionary):
	darkOverlay.visible = false

	var success: bool = GlobalData.add_kept_suspect(data)

	if not success:
		if GlobalData.is_suspect_list_full():
			dialogue_box.start_dialogue(
				"global_alerts",
				"suspect_list_full"
			)

		pop_button.disabled = false
		keep_button.disabled = false
		return

	GlobalData.check_reveal_from_kept(data)

	if GlobalData.kept_suspects.size() == 5:
		dialogue_box.start_dialogue(
			"global_alerts",
			"suspect_list_almost_full"
		)

	_do_pop()


func on_keep_cancelled():
	darkOverlay.visible = false

	pop_button.disabled = false
	keep_button.disabled = false
