extends Control

@onready var id_label = $id_suspect
@onready var name_title_label = $nama_suspect_Label
@onready var name_label = $nama_suspect
@onready var gender_label = $gender_suspect
@onready var age_label = $umur_suspect
@onready var weight_label = $beratbadan_suspect
@onready var height_label = $tinggibadan_suspect
@onready var blood_label = $golongandarah_suspect

var suspects: Array = []

func _ready():
	randomize()
	load_suspects()
	show_random_suspect()


func load_suspects():
	var file := FileAccess.open("res://data/suspects.json", FileAccess.READ)

	if file == null:
		push_error("Cannot open suspects.json")
		return

	var parsed = JSON.parse_string(file.get_as_text())

	if parsed == null:
		push_error("Invalid JSON format")
		return

	suspects = parsed


func show_random_suspect():
	if suspects.is_empty():
		push_error("No suspect data found")
		return

	var suspect: Dictionary = suspects.pick_random()
	show_suspect(suspect)


func show_suspect(suspect: Dictionary):
	id_label.text = str(suspect.get("id", "-"))

	name_title_label.text = str(suspect.get("nama", "-"))
	name_label.text = str(suspect.get("nama", "-"))

	gender_label.text = get_gender_icon(str(suspect.get("gender", "")))

	age_label.text = "%s Tahun" % str(suspect.get("umur", "-"))
	height_label.text = "%s cm" % str(suspect.get("tinggi_cm", "-"))
	blood_label.text = str(suspect.get("golongan_darah", "-"))

	if suspect.has("berat_kg"):
		weight_label.text = "%s kg" % str(suspect["berat_kg"])
	else:
		weight_label.text = "-"


func get_gender_icon(gender: String) -> String:
	match gender:
		"Laki-laki":
			return "👨"
		"Perempuan":
			return "👩"
		_:
			return "❓"
