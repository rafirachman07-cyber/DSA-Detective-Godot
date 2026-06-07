extends Node2D

@onready var idOdp = $ODPCard/id_odp
@onready var namaOdp = $ODPCard/nama_odp
@onready var genderOdp = $ODPCard/gender_odp
@onready var umurOdp = $ODPCard/umur_odp
@onready var beratOdp = $ODPCard/berat_odp
@onready var tinggiOdp = $ODPCard/tinggi_odp
@onready var goldarOdp = $ODPCard/goldar_odp
@onready var photoOdp = $ODPCard/photo_odp
@onready var stempel = $ODPCard/Stempel
@onready var sensor1 = $ODPCard/Sensor_1
@onready var sensor2 = $ODPCard/Sensor_2
@onready var sensor3 = $ODPCard/Sensor_3
@onready var sensor4 = $ODPCard/Sensor_4
@onready var sensor5 = $ODPCard/Sensor_5

@onready var ODPCard = $ODPCard

@onready var failed = $Failed
@onready var suceed = $Suceed


func _ready() -> void:
	var selected_suspect = GlobalData.selected_kept_suspect 
	var odp = GlobalData.current_odp
	
	GlobalData.is_censored = false
	show_odp_card(odp)
	
	if selected_suspect == odp:
		suceed.visible = true
	else:
		failed.visible = true
		

func show_odp_card(data: Dictionary):
	idOdp.text = str(data.get("id", "-"))
	namaOdp.text = str(data.get("name", "-"))
	genderOdp.text = get_gender_text(data.get("is_male", true))
	umurOdp.text = str(data.get("age", "-"))
	beratOdp.text = "%s kg" % str(data.get("weight_kg", "-"))
	tinggiOdp.text = "%s cm" % str(data.get("height_cm", "-"))
	goldarOdp.text = str(data.get("blood_type", "-"))
	
	sensor1.visible = false
	sensor2.visible = false
	sensor3.visible = false
	sensor4.visible = false
	sensor5.visible = false

	var path := str(data.get("sprite", "")).replace("./", "res://assets/characters/")
	photoOdp.texture = load(path)	


func get_gender_text(is_male: bool) -> String:
	if is_male:
		return "♂"
	else:
		return "♀"


func _on_play_again_pressed() -> void:
	GlobalData.reset()
	get_tree().change_scene_to_file("res://scripts/main_menu.tscn")
