extends Control

signal confirmed
signal cancelled

@onready var odp_card = $ODPCard
@onready var queue_card = $QueuePersonCard
@onready var setuju_button = $KeepConfirmPanel/SetujuButton
@onready var batal_button = $KeepConfirmPanel/BatalkanButton
@onready var label_confirmation = $LabelConfirmation
@onready var keepConfirmPanel = $KeepConfirmPanel
@onready var confirmDataBox = $KeepConfirmPanel/DataBox
@onready var labelConfirmation = $KeepConfirmPanel/LabelConfirmation
@onready var confirmIdSuspect = $KeepConfirmPanel/DataBox/id_suspect_confirm
@onready var genderSuspectConfirm = $KeepConfirmPanel/DataBox/gender_suspect_confirm
@onready var namaSuspectConfirm = $KeepConfirmPanel/DataBox/nama_suspect_Label_confirm
@onready var umurSuspsectConfirm = $KeepConfirmPanel/DataBox/umur_suspect_confirm
@onready var beratSuspectConfirm = $KeepConfirmPanel/DataBox/berat_suspect_confirm
@onready var tinggiSuspectConfirm = $KeepConfirmPanel/DataBox/tinggi_suspect_confirm
@onready var goldarSuspectConfirm = $KeepConfirmPanel/DataBox/goldar_suspect_confirm
@onready var labelNamaSuspectConfirm = $KeepConfirmPanel/DataBox/nama_suspect_Label_confirm
@onready var imageSuspectConfirm = $KeepConfirmPanel/DataBox/image_suspect_confirm
@onready var idOdp = $KeepConfirmPanel/ODPCard/id_odp
@onready var namaOdp = $KeepConfirmPanel/ODPCard/nama_odp
@onready var genderOdp = $KeepConfirmPanel/ODPCard/gender_odp
@onready var umurOdp = $KeepConfirmPanel/ODPCard/umur_odp
@onready var beratOdp = $KeepConfirmPanel/ODPCard/berat_odp
@onready var tinggiOdp = $KeepConfirmPanel/ODPCard/tinggi_odp
@onready var goldarOdp = $KeepConfirmPanel/ODPCard/goldar_odp
@onready var photoOdp = $KeepConfirmPanel/ODPCard/photo_odp
@onready var stempel = $KeepConfirmPanel/ODPCard/Stempel
@onready var sfx_player = $SFXPlayer

var queue_person_data: Dictionary = {}

var sfx = {
	"popping": preload("res://assets/audio/pop.mp3"),
	"keep": preload("res://assets/audio/keep.mp3"),
}

func _ready():
	visible = false
	setuju_button.pressed.connect(_on_setuju_pressed)
	batal_button.pressed.connect(_on_batal_pressed)

func play_sfx(key: String):
	if not sfx.has(key):
		return

	sfx_player.stream = sfx[key]
	sfx_player.play()
	
func open(odp_data: Dictionary, queue_data: Dictionary):
	queue_person_data = queue_data

	show_odp_card(odp_data)
	show_queue_card(queue_data)

	labelConfirmation.text = 'Yakin ingin keep \n"%s" ke suspect list?' % str(queue_data.get("first_name", "-"))

	visible = true
	keepConfirmPanel.visible = true
	keepConfirmPanel.z_index = 1001
	
func show_odp_card(data: Dictionary):
	idOdp.text = str(data.get("id", "-"))
	namaOdp.text = str(data.get("name", "-"))
	genderOdp.text = get_gender_text(data.get("is_male", true))
	umurOdp.text = str(data.get("age", "-"))
	beratOdp.text = "%s kg" % str(data.get("weight_kg", "-"))
	tinggiOdp.text = "%s cm" % str(data.get("height_cm", "-"))
	goldarOdp.text = str(data.get("blood_type", "-"))

	var path := str(data.get("sprite", "")).replace("./", "res://assets/characters/")
	photoOdp.texture = load(path)

func show_queue_card(data: Dictionary):
	confirmIdSuspect.text = str(data.get("id", "-"))
	labelNamaSuspectConfirm.text = str(data.get("name", "-"))
	namaSuspectConfirm.text = str(data.get("name", "-"))
	genderSuspectConfirm.text = get_gender_text(data.get("is_male", true))
	umurSuspsectConfirm.text = str(data.get("age", "-"))
	beratSuspectConfirm.text = "%s kg" % str(data.get("weight_kg", "-"))
	tinggiSuspectConfirm.text = "%s cm" % str(data.get("height_cm", "-"))
	goldarSuspectConfirm.text = str(data.get("blood_type", "-"))

	var path := str(data.get("sprite", "")).replace("./", "res://assets/characters/")
	imageSuspectConfirm.texture = load(path)

func get_gender_text(is_male: bool) -> String:
	if is_male:
		return "♂"
	else:
		return "♀"
		
func close():
	visible = false

func _on_setuju_pressed():
	play_sfx("keep")
	confirmed.emit(queue_person_data)
	close()

func _on_batal_pressed():
	cancelled.emit()
	close()
