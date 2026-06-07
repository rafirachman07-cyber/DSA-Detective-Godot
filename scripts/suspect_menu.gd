extends Node2D

var icon_font = preload("res://assets/fonts/Thabit.ttf")
var kept_item_scene = preload("res://scripts/kept_suspect_item.tscn")

#Suspect
@onready var id_suspect = $Background/Board/SuspectCard/id_suspect
@onready var nama_suspect_Label = $Background/Board/SuspectCard/nama_suspect_Label
@onready var nama_suspect = $Background/Board/SuspectCard/nama_suspect
@onready var gender_suspect = $Background/Board/SuspectCard/gender_suspect
@onready var umur_suspect = $Background/Board/SuspectCard/umur_suspect
@onready var beratbadan_suspect = $Background/Board/SuspectCard/beratbadan_suspect
@onready var tinggibadan_suspect = $Background/Board/SuspectCard/tinggibadan_suspect
@onready var golongandarah_suspect = $Background/Board/SuspectCard/golongandarah_suspect
@onready var suspect_image = $Background/Board/SuspectCard/image_suspect

#Suspect Hover
@onready var suspect_list_box = $Background/Board/SuspectList/VBoxContainer
@onready var suspect_list_grid = $Background/Board/SuspectList/GridContainer
@onready var hover_preview = $Background/Board/SuspectList/HoverPreviewPanel

@onready var preview_image = $Background/Board/SuspectList/HoverPreviewPanel/image_suspect_preview
@onready var preview_name = $Background/Board/SuspectList/HoverPreviewPanel/nama_suspect_preview
@onready var preview_name_label = $Background/Board/SuspectList/HoverPreviewPanel/nama_suspect_Label_preview
@onready var preview_id = $Background/Board/SuspectList/HoverPreviewPanel/id_suspect_preview
@onready var preview_age = $Background/Board/SuspectList/HoverPreviewPanel/umur_suspect_preview
@onready var preview_gender = $Background/Board/SuspectList/HoverPreviewPanel/gender_suspect_preview
@onready var preview_height = $Background/Board/SuspectList/HoverPreviewPanel/tinggi_suspect_preview
@onready var preview_weight = $Background/Board/SuspectList/HoverPreviewPanel/berat_suspect_preview
@onready var preview_blood = $Background/Board/SuspectList/HoverPreviewPanel/goldar_suspect_preview

#dialog
@onready var dialogue_box = $DialogBox
var dialogue_step: String = "none"

var suspects: Array = []

func _ready():
	#DIALOG 
	#1. PROLOG
	if not GlobalData.tutorials_completed.get("prolog", false):
		dialogue_box.dialogue_finished.connect(_on_tutorial_selesai)
		dialogue_step = "prolog"
		dialogue_box.start_dialogue("prolog") # Memanggil key "prolog" dari JSON
		
	# 2. SUSPECT MENU
	elif not GlobalData.tutorials_completed.get("suspect_menu", false):
		dialogue_box.dialogue_finished.connect(_on_tutorial_selesai)
		dialogue_step = "suspect_menu"
		dialogue_box.start_dialogue("suspect_menu") # Memanggil key "suspect_menu" dari JSON
	
	# 3. CHOOSE SUSPECT
	elif _apakah_semua_broker_selesai() and not GlobalData.tutorials_completed.get("choose_suspect_menu", false):
		dialogue_box.dialogue_finished.connect(_on_tutorial_selesai)
		dialogue_step = "choose_suspect_menu"
		dialogue_box.start_dialogue("choose_suspect_menu")
	else:
		dialogue_box.hide()
		
	start_game_logic() #mindahin reload suspect ke fungsi ini

#====================== fungsi buat dialog start =====================
func _on_tutorial_selesai():
	if dialogue_step == "prolog":
		GlobalData.tutorials_completed["prolog"] = true
		
		if not GlobalData.tutorials_completed.get("suspect_menu", false):
			dialogue_step = "suspect_menu"
			dialogue_box.start_dialogue("suspect_menu")
		else:
			_check_broker_and_go_next()
			
	elif dialogue_step == "suspect_menu":
		GlobalData.tutorials_completed["suspect_menu"] = true
		_check_broker_and_go_next()
			
	elif dialogue_step == "choose_suspect_menu":
		GlobalData.tutorials_completed["choose_suspect_menu"] = true
		dialogue_step = "none"
		start_game_logic()

func _check_broker_and_go_next():
	if _apakah_semua_broker_selesai() and not GlobalData.tutorials_completed.get("choose_suspect_menu", false):
		dialogue_step = "choose_suspect_menu"
		dialogue_box.start_dialogue("choose_suspect_menu")
	else:
		dialogue_step = "none"
		start_game_logic()

func _apakah_semua_broker_selesai() -> bool:
	return GlobalData.tutorials_completed.get("stack_menu", false) \
	   and GlobalData.tutorials_completed.get("queue_orang_menu", false) \
	   and GlobalData.tutorials_completed.get("queue_fax_menu", false) \
	   and GlobalData.tutorials_completed.get("hashmap_menu", false)
# ======================= fungsi buat dialog end ======================

func start_game_logic():
	hover_preview.visible = false
	refresh_suspect_list()
	load_suspects()
	
	if GlobalData.suspect_already_selected:
		show_suspect(GlobalData.selected_suspect)
	else:
		var suspect = suspects.pick_random()
		GlobalData.selected_suspect = suspect
		GlobalData.suspect_already_selected = true
		GlobalData.load_and_split(GlobalData.selected_suspect)
		show_suspect(suspect)
	
	refresh_suspect_list()

func refresh_suspect_list():
	for child in suspect_list_grid.get_children():
		child.queue_free()
	
	suspect_list_grid.columns = 2
	
	for suspect in GlobalData.kept_suspects:
		var item = kept_item_scene.instantiate()
	
		item.custom_minimum_size = Vector2(90, 120)
		item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		item.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
		suspect_list_grid.add_child(item)
		item.setup(suspect)
	
		item.mouse_entered.connect(func():
			show_hover_preview(suspect)
		)
	
		item.mouse_exited.connect(func():
			hide_hover_preview()
		)

func load_suspect_texture(sprite_path: String):
	if sprite_path == "":
		return null
	
	var fixed_path := sprite_path.replace("./", "res://assets/characters/")
	var texture = load(fixed_path)
	
	if texture == null:
		push_error("Cannot load suspect image: " + fixed_path)
	
	return texture

func show_hover_preview(suspect: Dictionary):
	preview_name_label.text = str(suspect.get("name", "-"))
	preview_name.text = str(suspect.get("first_name", "-"))
	preview_id.text = str(suspect.get("id", "-"))
	preview_age.text = str(suspect.get("age", "-"))
	preview_gender.text = get_gender_icon(bool(suspect.get("is_male", true)))
	preview_height.text = "%s cm" % str(suspect.get("height_cm", "-"))
	preview_weight.text = "%s kg" % str(suspect.get("weight_kg", "-"))
	preview_blood.text = str(suspect.get("blood_type", "-"))
	
	preview_image.texture = load_suspect_texture(str(suspect.get("sprite", "")))
	
	hover_preview.visible = true
	hover_preview.z_index = 999

func load_suspects():
	var file := FileAccess.open("res://assets/characters/characters.json", FileAccess.READ)
	
	if file == null:
		push_error("Cannot open characters.json")
		return
	
	var parsed = JSON.parse_string(file.get_as_text())
	
	if parsed == null:
		push_error("Invalid JSON format")
		return
	
	suspects = parsed
	
	print("Loaded characters: ", suspects.size())

func hide_hover_preview():
	hover_preview.visible = false

func show_random_suspect():
	if suspects.is_empty():
		push_error("No suspect data found")
		return
	
	var suspect: Dictionary = suspects.pick_random()
	show_suspect(suspect)


func show_suspect(suspect: Dictionary):
	id_suspect.text = str(suspect.get("id", "-"))
	
	nama_suspect_Label.text = str(suspect.get("name", "-"))
	nama_suspect.text = str(suspect.get("name", "-"))
	
	gender_suspect.text = get_gender_icon(bool(suspect.get("is_male", true)))
	
	umur_suspect.text = "%d Tahun" % int(suspect.get("age", 0))
	beratbadan_suspect.text = "%d kg" % int(suspect.get("weight_kg", 0))
	tinggibadan_suspect.text = "%d cm" % int(suspect.get("height_cm", 0))
	golongandarah_suspect.text = str(suspect.get("blood_type", "-"))
	
	load_suspect_image(str(suspect.get("sprite", "")))


func get_gender_icon(is_male: bool) -> String:
	if is_male:
		return "♂"
	else:
		return "♀"


func load_suspect_image(sprite_path: String):
	if sprite_path == "":
		return
	
	var fixed_path := sprite_path.replace("./", "res://assets/characters/")
	
	var texture = load(fixed_path)
	
	if texture == null:
		push_error("Cannot load suspect image: " + fixed_path)
		return
	
	suspect_image.texture = texture

func _on_queue_button_pressed():
	get_tree().change_scene_to_file("res://scripts/queue_menu.tscn")


func _on_back_button_pressed():
	GlobalData.reset()
	get_tree().change_scene_to_file("res://scripts/main_menu.tscn")

func _on_stack_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scripts/stack_menu.tscn")

func _on_hash_map_pressed() -> void:
	get_tree().change_scene_to_file("res://scripts/hashmap_menu.tscn")
