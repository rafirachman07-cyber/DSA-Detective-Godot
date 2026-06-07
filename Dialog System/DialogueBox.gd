extends CanvasLayer

@onready var portrait_rect = $DialogPanel/potrait_char
@onready var name_label = $DialogPanel/Label_name
@onready var text_label = $DialogPanel/PanelContainer/dialog

# Alamat file JSON Master yang kita buat di Langkah 2
const MASTER_JSON_PATH = "res://Dialog System/dialog_master.json"

var dialogue_data: Array = []
var current_index: int = 0

signal dialogue_finished

func _ready():
	hide()

func start_dialogue(dialogue_key: String):
	if not FileAccess.file_exists(MASTER_JSON_PATH):
		print("Error: File JSON tidak ditemukan!")
		return
	
	var file = FileAccess.open(MASTER_JSON_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var parsed_data = JSON.parse_string(json_string)
	
	if parsed_data is Dictionary and parsed_data.has(dialogue_key):
		dialogue_data = parsed_data[dialogue_key]
		current_index = 0
		show()
		show_current_line()
	else:
		print("Error: Key '" + dialogue_key + "' tidak ditemukan di JSON.")

func show_current_line():
	if current_index >= dialogue_data.size():
		finish_dialogue()
		return
	
	var current_line = dialogue_data[current_index]
	name_label.text = current_line["name"]
	text_label.text = current_line["text"]
	
	var path_gambar = current_line["portrait"]
	if ResourceLoader.exists(path_gambar):
		portrait_rect.texture = load(path_gambar)
	else:
		portrait_rect.texture = null

func _input(event):
	if not visible:
		return
		
	# 1. ACTION LANJUTKAN DIALOG (Space/Enter/Klik Kiri)
	if event.is_action_pressed("ui_accept"):
		current_index += 1
		show_current_line()
		
	# 2. ACTION SKIP DIALOG LEWAT KEYBOARD (Tombol Escape / ui_cancel)
	elif event.is_action_pressed("ui_cancel"):
		finish_dialogue()

func finish_dialogue():
	hide()
	dialogue_finished.emit()
