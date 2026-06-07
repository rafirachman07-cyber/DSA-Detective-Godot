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

#Confirm Box
@onready var confirmation_tab = $ConfirmationTab
@onready var batalkanButton = $KeepConfirmPanel/BatalkanButton
@onready var setujuButton = $KeepConfirmPanel/SetujuButton
@onready var darkOverlay = $Background/darkOverlay

# point this to your Control node
@onready var card_stack_control = $Background/Board/Paper/Bg/CardStack

const CARD_SIZE = Vector2(100, 150)  # replace with your actual PNG size
const STACK_OFFSET = Vector2(-30, 0)
const MAX_BEHIND = 6

var card_scene = preload("res://scripts/paper.tscn")
var card_size := Vector2.ZERO

var is_processing := false
var people_data = []
var current_loop_data = []
var current_loop_count = ONE_LOOP_COUNT

var pending_action: Callable = Callable()
var dialogue_step := "none"

var people_data: Array = []

# Loop Handler
const ONE_LOOP_COUNT = 8
var current_loop_data = []
var current_loop_count = ONE_LOOP_COUNT
var is_loop_empty = false

@onready var dialogue_box = $DialogBox

func _ready():
	#DIALOG
	# 1. CEK APAKAH TUTORIAL BELUM PERNAH DIJALANKAN
	if not GlobalData.tutorials_completed.get("stack_menu", false):
		dialogue_box.dialogue_finished.connect(_on_tutorial_selesai)
		dialogue_box.start_dialogue("stack_menu")
		GlobalData.tutorials_completed["stack_menu"] = true
	else:
		#JIKA SUDAH DI HIDE
		dialogue_box.hide()
		print("Tutorial untuk Stack Menu sudah pernah dilewati.")
	
	randomize()

	gender_label.add_theme_font_override("font", icon_font)
	peek_button.pressed.connect(on_peek_pressed)
	pop_button.pressed.connect(on_pop_pressed)
	keep_button.pressed.connect(on_keep_pressed)
	back_button.pressed.connect(on_back_pressed)
	push_button.pressed.connect(on_push_pressed)
	
	# Untuk Confirmation tab
	confirmation_tab.confirmed.connect(on_keep_confirmed)
	confirmation_tab.cancelled.connect(on_keep_cancelled)

	mask.visible = true
	kosong.visible = false
	push_button.visible = false
	pop_button.visible = false
	keep_button.visible = false
	peek_button.visible = true

	load_people_data()
	
	if GlobalData.curr_stack_data.is_empty():
		GlobalData.curr_stack_data = pick_and_pop()
	
	current_loop_data = GlobalData.curr_stack_data

	current_loop_data = GlobalData.curr_stack_data  # pull after potential pic

	# measure actual card size after one frame
	var temp = card_scene.instantiate()
	card_stack_control.add_child(temp)
	await get_tree().process_frame
	card_size = temp.size
	temp.queue_free()

	darkOverlay.color = Color(0, 0, 0, 0.55)
	darkOverlay.visible = false
	darkOverlay.z_index = 900

	rebuild_stack()
	clear_data_box()

func _on_tutorial_selesai():
	print("Player selesai membaca tutorial, game bisa dilanjutkan!")

func load_people_data():
	var type = GlobalData.Broker.STACK
	people_data = GlobalData.get_list(type)

	print("Loaded data: ", people_data.size())


func pick_and_pop() -> Array:
	var picked := people_data.slice(0, ONE_LOOP_COUNT)
	people_data = people_data.slice(ONE_LOOP_COUNT)
	GlobalData.lists[GlobalData.Broker.STACK] = people_data  # ← sync back
	return picked


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

	# i=0 is back card, i=visible_count-1 is front card
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

	peek_button.visible = false
	mask.visible = false
	pop_button.visible = true
	keep_button.visible = true

	peek_front()


func on_pop_pressed():
	
	if is_processing or current_loop_data.is_empty() or current_loop_count <= 0:
		return

	is_processing = true

	var all_children = card_stack_control.get_children()
	var top_card = all_children.back()
	var remaining_children = all_children.slice(0, all_children.size() - 1)

	# slide top card downward
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

	# spawn new back card at its final position immediately (no offset)
	if current_loop_data.size() > remaining_children.size():
		var new_card = card_scene.instantiate()
		card_stack_control.add_child(new_card)
		card_stack_control.move_child(new_card, 0)
		new_card.setup(null)
		new_card.z_index = 0

		var back_depth = visible_count - 1
		var back_pos = Vector2(front_x - abs(STACK_OFFSET.x) * back_depth, origin_y)
		new_card.position = back_pos

	# shift existing cards (not the new one) rightward first to reveal new card
	var reveal_tween = create_tween()
	var existing = card_stack_control.get_children()
	# skip index 0 which is the new back card
	for i in range(1, existing.size()):
		var current_pos = existing[i].position
		reveal_tween.parallel().tween_property(existing[i], "position", current_pos + Vector2(abs(STACK_OFFSET.x), 0), 0.15)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_QUART)

	await reveal_tween.finished

	# now shift everything including new card into final centered positions
	var shift_tween = create_tween()
	var all_cards = card_stack_control.get_children()
	for i in all_cards.size():
		var depth = all_cards.size() - 1 - i
		var target_pos = Vector2(front_x - abs(STACK_OFFSET.x) * depth, origin_y)
		shift_tween.parallel().tween_property(all_cards[i], "position", target_pos, 0.25)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_QUART)
		all_cards[i].z_index = i

	await shift_tween.finished

	is_processing = false
	peek_front()


func on_keep_pressed():
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

	var data: Dictionary = current_loop_data.back()  # was queue[0]
	show_data_box(data)

	pop_button.disabled = false
	keep_button.disabled = false


func show_empty_state():
	clear_data_box()
	pop_button.visible = false
	keep_button.visible = false
	peek_button.visible = false
	push_button.visible = true
	kosong.visible = true


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
	name_label.text = ""
	age_label.text = ""
	gender_label.text = ""
	height_label.text = ""
	weight_label.text = ""
	blood_label.text = ""


func get_gender_text(is_male: bool) -> String:
	return "♂" if is_male else "♀"


func on_back_pressed():
	get_tree().change_scene_to_file("res://scripts/suspect_menu.tscn")
	
func on_push_pressed():
	if people_data.is_empty() and current_loop_data.is_empty():
		print("No more data on stack")
		return
		
	current_loop_data = pick_and_pop()
	current_loop_count = ONE_LOOP_COUNT
	reset_ui_to_start()
	rebuild_stack()
	
func on_keep_confirmed(data: Dictionary):
	darkOverlay.visible = false

	if not GlobalData.kept_suspects.has(data):
		GlobalData.kept_suspects.append(data)

	on_pop_pressed()
	
func on_keep_cancelled():
	darkOverlay.visible = false

	pop_button.disabled = false
	keep_button.disabled = false
