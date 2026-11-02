#STORY SELECT
#Menu de seleccion de historia
#Luego habria q mejorar este menu
extends Control

#Simpleemtne se conectan los botones para que acada uno llame a su histoira
func _on_btn_story_click_pressed() -> void:
	_start_story("dummy")


func _on_btn_story_mouse_pressed() -> void:
	_start_story("historia_2")


func _on_btn_story_keyboard_pressed() -> void:
	_start_story("historia_3")

#COomenzar una historia, configura los datos en el global y cambia a la cinematica

func _start_story(story_id: String) -> void:
	GlobalState.current_mode = GlobalState.Mode.STORY
	GlobalState.current_story_id = story_id
	GlobalState.current_cutscene_type = GlobalState.CutsceneType.INTRO
	GlobalState.reset_run()
	get_tree().change_scene_to_file("res://ui/cutscenes/cutscene_player.tscn")
