extends Control

@onready var panel = get_node_or_null("HoverPreviewPanel")

@onready var id_odp = get_node_or_null("HoverPreviewPanel/id_odp")
@onready var nama_odp = get_node_or_null("HoverPreviewPanel/nama_odp")
@onready var gender_odp = get_node_or_null("HoverPreviewPanel/gender_odp")
@onready var umur_odp = get_node_or_null("HoverPreviewPanel/umur_odp")
@onready var berat_odp = get_node_or_null("HoverPreviewPanel/berat_odp")
@onready var tinggi_odp = get_node_or_null("HoverPreviewPanel/tinggi_odp")
@onready var goldar_odp = get_node_or_null("HoverPreviewPanel/goldar_odp")
@onready var photo_odp = get_node_or_null("HoverPreviewPanel/image_odp")


func _ready():
	var sensor_num = GlobalData.sensor_choice
	get_node("Sensor_%d" % sensor_num).visible = true
	
	visible = false
	debug_nodes()


func debug_nodes():
	print("panel: ", panel)
	print("id_odp: ", id_odp)
	print("nama_odp: ", nama_odp)
	print("gender_odp: ", gender_odp)
	print("umur_odp: ", umur_odp)
	print("berat_odp: ", berat_odp)
	print("tinggi_odp: ", tinggi_odp)
	print("goldar_odp: ", goldar_odp)
	print("photo_odp: ", photo_odp)


func open():
	show_data(GlobalData.selected_suspect)
	visible = true


func close():
	visible = false


func show_data(data: Dictionary):
	if id_odp == null:
		push_error("id_odp node tidak ditemukan. Cek nama/path node.")
		return

	id_odp.text = str(data.get("id", "-"))
	nama_odp.text = str(data.get("name", "-"))
	gender_odp.text = "♂" if data.get("is_male", true) else "♀"
	umur_odp.text = str(data.get("age", "-"))
	berat_odp.text = str(data.get("weight_kg", "-")) + " kg"
	tinggi_odp.text = str(data.get("height_cm", "-")) + " cm"
	goldar_odp.text = str(data.get("blood_type", "-"))

	var path := str(data.get("sprite", "")).replace("./", "res://assets/characters/")

	if ResourceLoader.exists(path):
		photo_odp.texture = load(path)
