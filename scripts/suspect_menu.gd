extends Node2D

var icon_font = preload("res://assets/fonts/Thabit.ttf")

@onready var id_suspect = $Background/Board/SuspectCard/id_suspect
@onready var nama_suspect_Label = $Background/Board/SuspectCard/nama_suspect_Label
@onready var nama_suspect = $Background/Board/SuspectCard/nama_suspect
@onready var gender_suspect = $Background/Board/SuspectCard/gender_suspect
@onready var umur_suspect = $Background/Board/SuspectCard/umur_suspect
@onready var beratbadan_suspect = $Background/Board/SuspectCard/beratbadan_suspect
@onready var tinggibadan_suspect = $Background/Board/SuspectCard/tinggibadan_suspect
@onready var golongandarah_suspect = $Background/Board/SuspectCard/golongandarah_suspect
@onready var suspect_image = $Background/Board/SuspectCard/image_suspect

var suspects: Array = []
func _ready():
	load_suspects()

	if GlobalData.suspect_already_selected:
		show_suspect(GlobalData.selected_suspect)
	else:
		var suspect = suspects.pick_random()
		GlobalData.selected_suspect = suspect
		GlobalData.suspect_already_selected = true
		show_suspect(suspect)


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
		get_tree().change_scene_to_file("res://scripts/main_menu.tscn")
