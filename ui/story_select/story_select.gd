extends Control

# Conecta el botón de la historia 1 (Cliqueo) a esta función
func _on_btn_story_click_pressed() -> void:
	_start_story("dummy")

# Conecta el botón de la historia 2 (Movimiento) a esta función
func _on_btn_story_mouse_pressed() -> void:
	_start_story("historia_2")

# Conecta el botón de la historia 3 (Teclado) a esta función
func _on_btn_story_keyboard_pressed() -> void:
	_start_story("historia_3")

func _start_story(story_id: String) -> void:
	GlobalState.current_mode = GlobalState.Mode.STORY
	GlobalState.current_story_id = story_id
	GlobalState.current_cutscene_type = GlobalState.CutsceneType.INTRO
	GlobalState.reset_run()
	get_tree().change_scene_to_file("res://ui/cutscenes/cutscene_player.tscn")
