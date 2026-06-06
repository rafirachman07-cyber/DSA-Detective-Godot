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

@onready var form = $Background/Board/Paper/TextureRect/LineEdit
@onready var search_button = $Background/Board/Paper/SearchButton

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


func _ready():
	randomize()

	gender_label.add_theme_font_override("font", icon_font)
	back_button.pressed.connect(on_back_pressed)
	search_button.pressed.connect(on_search_pressed)
	form.text_submitted.connect(func(_t): on_search_pressed())

	mask.visible = true
	pop_button.visible = false
	keep_button.visible = false

	load_people_data()
	clear_data_box()
	switch_texture("searching")


func load_people_data():
	var list = GlobalData.get_list(GlobalData.Broker.HASH_MAP)
	for person in list:
		people_map[person["id"]] = person
	print("Loaded into hashmap: ", people_map.size(), " entries")


func on_search_pressed():
	var raw: String= form.text.strip_edges()
	print(raw)
	
	if raw.is_empty():
		switch_texture("searching")
		clear_data_box()
		return

	if not raw.is_valid_int():
		switch_texture("not_found")
		clear_data_box()
		return

	var target_id := raw.to_int()

	if not people_map.has(target_id):
		switch_texture("not_found")
		clear_data_box()
		return

	switch_texture("found")
	show_data_box(people_map[target_id])


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
