extends Node2D

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scripts/loadingscreen.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
