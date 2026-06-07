extends TextureRect

func _ready():
	var sensor_num = GlobalData.sensor_choice
	get_node("Sensor_%d" % sensor_num).visible = true
