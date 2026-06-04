extends Node2D

var icon_font = preload("res://assets/fonts/Thabit.ttf")

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

# point this to your Control node
@onready var card_stack_control = $Background/Board/Paper/Bg/CardStack

const CARD_SIZE = Vector2(100, 150)  # replace with your actual PNG size
const STACK_OFFSET = Vector2(-30, 0)
const MAX_BEHIND = 6

var card_scene = preload("res://scripts/paper.tscn")
var card_size := Vector2.ZERO

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
	kosong.visible = false
	peek_button.visible = true
	pop_button.visible = false
	keep_button.visible = false

	load_people_data()

	# measure actual card size after one frame
	var temp = card_scene.instantiate()
	card_stack_control.add_child(temp)
	await get_tree().process_frame
	card_size = temp.size
	temp.queue_free()

	# fill queue from people_data
	queue = people_data.duplicate()

	rebuild_stack()
	clear_data_box()


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


func rebuild_stack():
	for child in card_stack_control.get_children():
		child.queue_free()

	if queue.is_empty():
		return

	var visible_count = min(queue.size(), MAX_BEHIND + 1)
	var total_spread = abs(STACK_OFFSET.x) * (visible_count - 1)
	var stack_width = card_size.x + total_spread
	var stack_height = card_size.y

	var origin_x = (card_stack_control.size.x - stack_width) / 2.0
	var origin_y = (card_stack_control.size.y - stack_height) / 2.0
	var front_x = origin_x + total_spread
	var front_y = origin_y

	var throw_start_x = card_size.x + 30.0

	for i in range(visible_count - 1, -1, -1):
		var card = card_scene.instantiate()
		card_stack_control.add_child(card)

		var depth = visible_count - 1 - i
		var target_pos = Vector2(front_x + STACK_OFFSET.x * depth, front_y)

		# start off to the left
		card.position = Vector2(throw_start_x, front_y)
		card.z_index = i

		if i == 0:
			card.setup(queue.back())
		else:
			card.setup(null)

		# stagger delay so back cards land first, front card last
		var delay = (visible_count - 1 - i) * 0.08

		var tween = create_tween()
		tween.tween_interval(delay)
		tween.tween_property(card, "position", target_pos, 0.35)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_BACK)


func on_peek_pressed():
	if is_processing or queue.is_empty():
		return

	peek_button.visible = false
	mask.visible = false
	pop_button.visible = true
	keep_button.visible = true

	peek_front()


func on_pop_pressed():
	if is_processing or queue.is_empty():
		return

	is_processing = true

	queue.pop_back()  # was pop_front()
	rebuild_stack()

	is_processing = false

	if queue.is_empty():
		show_empty_state()
	else:
		peek_front()


func on_keep_pressed():
	if is_processing or queue.is_empty():
		return

	is_processing = true

	var top = queue.pop_back()   # was pop_front()
	queue.push_front(top)        # put it at the bottom of the stack
	rebuild_stack()

	is_processing = false
	peek_front()


func peek_front():
	if queue.is_empty():
		clear_data_box()
		pop_button.disabled = true
		keep_button.disabled = true
		return

	var data: Dictionary = queue.back()  # was queue[0]
	show_data_box(data)

	pop_button.disabled = false
	keep_button.disabled = false


func show_empty_state():
	clear_data_box()
	pop_button.visible = false
	keep_button.visible = false
	peek_button.visible = false
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
