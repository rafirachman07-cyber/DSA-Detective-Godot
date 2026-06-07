extends CanvasLayer

@onready var portrait_rect = $DialogPanel/potrait_char
@onready var name_label = $DialogPanel/Label_name
@onready var text_label = $DialogPanel/PanelContainer/dialog

const MASTER_JSON_PATH = "res://Dialog System/dialog_master.json"

var dialogue_database: Dictionary = {}
var current_dialogue: Array = []
var current_index: int = 0

signal dialogue_finished


func _ready():
	hide()
	load_dialogue_json()


func load_dialogue_json():
	var file := FileAccess.open(MASTER_JSON_PATH, FileAccess.READ)

	if file == null:
		push_error("Cannot open dialogue JSON: " + MASTER_JSON_PATH)
		return

	var parsed = JSON.parse_string(file.get_as_text())

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Dialogue JSON root must be Dictionary/Object")
		return

	dialogue_database = parsed
	print("Dialogue loaded. Keys: ", dialogue_database.keys())


func start_dialogue(scene_key: String, trigger_key: String):
	if dialogue_database.is_empty():
		load_dialogue_json()

	if not dialogue_database.has("scenes"):
		push_error("Key 'scenes' tidak ditemukan")
		return

	var scenes: Dictionary = dialogue_database["scenes"]

	if not scenes.has(scene_key):
		push_error("Scene tidak ditemukan: " + scene_key)
		return

	var scene_data: Dictionary = scenes[scene_key]

	if not scene_data.has(trigger_key):
		push_error("Trigger tidak ditemukan: " + scene_key + "/" + trigger_key)
		return

	current_dialogue = scene_data[trigger_key]
	current_index = 0

	show()
	show_current_line()


func show_current_line():
	if current_index >= current_dialogue.size():
		finish_dialogue()
		return

	var current_line: Dictionary = current_dialogue[current_index]

	name_label.text = str(current_line.get("name", ""))
	text_label.text = str(current_line.get("text", ""))

	var path_gambar := str(current_line.get("portrait", ""))

	if ResourceLoader.exists(path_gambar):
		portrait_rect.texture = load(path_gambar)
	else:
		portrait_rect.texture = null


func _input(event):
	if not visible:
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()

		current_index += 1
		show_current_line()

	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		finish_dialogue()


func finish_dialogue():
	hide()
	current_dialogue = []
	current_index = 0

	await get_tree().process_frame

	dialogue_finished.emit()
