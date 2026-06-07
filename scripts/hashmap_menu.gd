extends Node2D

var icon_font = preload("res://assets/fonts/Thabit.ttf")

@onready var suspect_image = $Background/Board/Paper/DataBox/image_suspect
@onready var mask = $Background/Board/Paper/Mask

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

@onready var formpar = $Background/Board/Paper/formpar
@onready var form = $Background/Board/Paper/formpar/LineEdit
@onready var search_button = $Background/Board/Paper/SearchButton
@onready var bg_card = $Background/Board/Paper/bg


@onready var confirmation_tab = $confirmationTab
@onready var darkOverlay = $Background/darkOverlay

# ==================================
# Texture handler
# ==================================
@onready var bg_card = $Background/Board/Paper/bg

var textures: Dictionary = {
	"searching" : preload("res://assets/hashmap_searching.png"),
	"found" : preload("res://assets/hashmap_found.png"),
	"not_found" : preload("res://assets/hashmap_notfound.png"),
}

func switch_texture(key: String) -> void:
	if not textures.has(key):
		push_error("Texture key not found: %s" % key)
		return
	bg_card.texture = textures[key]

# ==================================

var is_processing := false
var people_map: Dictionary = {}   # id (int) → person (Dictionary)
var global_target_id;

#dialog
@onready var dialogue_box = $DialogBox

var textures: Dictionary = {
	"searching": preload("res://assets/hashmap_searching.png"),
	"found": preload("res://assets/hashmap_found.png"),
	"not_found": preload("res://assets/hashmap_notfound.png"),
}

var is_processing := false
var people_map: Dictionary = {}

var dialogue_step := "none"
var pending_action: Callable = Callable()


func _ready():
	randomize()

	gender_label.add_theme_font_override("font", icon_font)

	if not dialogue_box.dialogue_finished.is_connected(_on_tutorial_selesai):
		dialogue_box.dialogue_finished.connect(_on_tutorial_selesai)

	back_button.pressed.connect(on_back_pressed)
	search_button.pressed.connect(on_search_pressed)
	form.text_submitted.connect(func(_t): on_search_pressed())
	keep_button.pressed.connect(on_keep_pressed)
	pop_button.pressed.connect(on_pop_pressed)
	
	# Untuk Confirmation tab
	confirmation_tab.confirmed.connect(on_keep_confirmed)
	confirmation_tab.cancelled.connect(on_keep_cancelled)

	mask.visible = true
	pop_button.visible = false
	pop_button.disabled = false
	
	keep_button.visible = false
	keep_button.disabled = false

	load_people_data()
	clear_data_box()
	switch_texture("searching")

	if not GlobalData.is_tutorial_completed("hashmap_menu"):
		dialogue_step = "hashmap_intro"
		dialogue_box.start_dialogue("hashmap_menu", "on_first_enter")
	else:
		dialogue_box.hide()


func _on_tutorial_selesai():
	if dialogue_step == "hashmap_intro":
		GlobalData.mark_tutorial_completed("hashmap_menu")
		dialogue_step = "none"

	elif dialogue_step == "hashmap_search":
		GlobalData.mark_tutorial_seen("hashmap_search")
		dialogue_step = "none"
		_run_pending_action()

	elif dialogue_step == "hashmap_result_rules":
		GlobalData.mark_tutorial_seen("hashmap_result_rules")
		dialogue_step = "none"


func _run_pending_action():
	if pending_action.is_valid():
		pending_action.call()

	pending_action = Callable()


func load_people_data():
	people_map.clear()

	var list = GlobalData.get_list(GlobalData.Broker.HASH_MAP)

	for person in list:
		people_map[int(person["id"])] = person

		var id: int = int(person["id"])
		people_map[id] = person
	print("Loaded into hashmap: ", people_map.size(), " entries")


func switch_texture(key: String) -> void:
	if not textures.has(key):
		push_error("Texture key not found: %s" % key)
		return

	bg_card.texture = textures[key]


func on_search_pressed():
	if is_processing:
		return

	if not GlobalData.has_seen_tutorial("hashmap_search"):
		dialogue_step = "hashmap_search"
		pending_action = Callable(self, "_do_search")
		dialogue_box.start_dialogue("hashmap_menu", "on_search_first_pressed")
		return

	_do_search()


func _do_search():
	is_processing = true

	var raw: String = form.text.strip_edges()

	print(raw)

	if raw.is_empty():
		switch_texture("searching")
		clear_data_box()
		is_processing = false
		return

	if not raw.is_valid_int():
		switch_texture("not_found")
		clear_data_box()
		is_processing = false
		return

	var target_id := raw.to_int()

	if not people_map.has(target_id):
		switch_texture("not_found")
		clear_data_box()
		is_processing = false
		return

	pop_button.visible = true
	pop_button.disabled = false
	keep_button.visible = true
	keep_button.disabled = true
	
	search_button.visible = false
	search_button.disabled = false
	formpar.visible = false

	switch_texture("found")
	show_data_box(people_map[target_id])

	if not GlobalData.has_seen_tutorial("hashmap_result_rules"):
		dialogue_step = "hashmap_result_rules"
		GlobalData.mark_tutorial_seen("hashmap_result_rules")
		dialogue_box.start_dialogue("hashmap_menu", "search_result_rules")

	is_processing = false

	global_target_id = target_id
	print("Found: ", people_map[target_id])  # add this
	

func show_data_box(data: Dictionary):
	id_label.text = "%s" % str(data.get("id", "-"))
	name_suspect_Label.text = str(data.get("name", "-"))
	name_label.text = str(data.get("name", "-"))
	age_label.text = "%s" % str(data.get("age", "-"))
	gender_label.text = "%s" % get_gender_text(data.get("is_male", true))
	height_label.text = "%s cm" % str(data.get("height_cm", "-"))
	weight_label.text = "%s kg" % str(data.get("weight_kg", "-"))
	blood_label.text = "%s" % str(data.get("blood_type", "-"))

	
	mask.visible = false
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

func reset_ui_to_start():
	formpar.visible = true
	search_button.visible = true
	pop_button.visible = false
	keep_button.visible = false
	mask.visible = true
	
	form.clear()
	
	switch_texture("searching")
	

func get_gender_text(is_male: bool) -> String:
	return "♂" if is_male else "♀"


func on_back_pressed():
	get_tree().change_scene_to_file("res://scripts/suspect_menu.tscn")
	
func on_keep_pressed():
	var selected_person: Dictionary = people_map[global_target_id]
	var odp_person: Dictionary = GlobalData.selected_suspect

	pop_button.disabled = true
	keep_button.disabled = true
	darkOverlay.visible = true
	confirmation_tab.open(odp_person, selected_person)
	
func on_keep_confirmed(data: Dictionary):
	darkOverlay.visible = false
	if not GlobalData.kept_suspects.has(data):
		GlobalData.kept_suspects.append(data)

	on_pop_pressed()
	
func on_keep_cancelled():
	darkOverlay.visible = false
	pop_button.disabled = false
	keep_button.disabled = false

func on_pop_pressed():
	reset_ui_to_start()
