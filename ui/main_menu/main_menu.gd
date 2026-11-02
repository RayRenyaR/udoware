extends Control

func _ready() -> void:
	# Asegurarnos de que el tiempo corra normal si venimos de un Game Over
	Engine.time_scale = 1.0

func _on_btn_story_mode_pressed() -> void:
	# Lleva al selector de personajes/historias
	get_tree().change_scene_to_file("res://ui/story_select/story_select.tscn")

func _on_btn_arcade_mode_pressed() -> void:
	# Configura el modo Arcade, resetea variables y lanza el Runner
	GlobalState.current_mode = GlobalState.Mode.ARCADE
	GlobalState.reset_run()
	get_tree().change_scene_to_file("res://core/runner/microgame_runner.tscn")
