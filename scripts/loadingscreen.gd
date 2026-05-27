extends Control

@onready var progress_bar = $Background/ProgressBar
@onready var tip_label = $Background/TipLabel
@onready var title = $Background/Title
@onready var loading_label = $Background/Loading
@onready var fade_rect = $Background/FadeRect

var target_scene := "res://scripts/suspect_menu.tscn"

var tips = [
	"Peek() untuk melihat data tersangka.",
	"Keep() mengirim tersangka ke belakang antrian.",
	"Pop() mengeluarkan tersangka dari antrian.",
	"Perhatikan tinggi badan dan golongan darah."
]


func _ready():
	randomize()

	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	tip_label.text = "Tip: " + tips.pick_random()
	loading_label.text = "Loading..."

	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.show_percentage = false

	await fake_loading()
	await fade_out_to_black()

	get_tree().change_scene_to_file(target_scene)


func fake_loading():
	for i in range(101):
		progress_bar.value = i
		await get_tree().create_timer(0.025).timeout


func fade_out_to_black():
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.6)
	await tween.finished
