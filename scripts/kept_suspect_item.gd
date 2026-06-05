extends Control

@onready var photo = $SuspectPhoto

var suspect_data: Dictionary = {}

func setup(data: Dictionary):
	suspect_data = data

	var sprite_path := str(data.get("sprite", ""))
	var fixed_path := sprite_path.replace("./", "res://assets/characters/")
	var texture = load(fixed_path)

	if texture != null:
		photo.texture = texture
