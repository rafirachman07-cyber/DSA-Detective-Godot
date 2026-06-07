extends Label

func play(text_value: String, start_pos: Vector2):
	text = text_value
	position = start_pos
	visible = true
	modulate.a = 0.0
	scale = Vector2.ONE
	rotation_degrees = randf_range(-8, 8)

	var target_pos := start_pos + Vector2(randf_range(-25, 25), -45)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.12)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12)
	tween.tween_property(self, "position", target_pos, 0.65)

	await tween.finished

	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(self, "modulate:a", 0.0, 0.25)
	fade.tween_property(self, "scale", Vector2(0.85, 0.85), 0.25)

	await fade.finished
	queue_free()
