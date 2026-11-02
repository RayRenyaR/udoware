#GAMEOVER
#Controla la pantalla de perdiste y utiliza el network bridge
extends Control

#Referencias
@onready var score_label: Label = $ScoreLabel
@onready var status_label: Label = $StatusLabel
@onready var retry_button: Button = $VBoxContainer/RetryButton
@onready var menu_button: Button = $VBoxContainer/MenuButton

#Apenas se instancia
func _ready() -> void:
	#Actaualizacion del texto
	score_label.text = "Rondas Superadas: %d" % GlobalState.score
	
	#Conectamos los botones
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Escuchamos la respuesta del puente de red
	NetworkBridge.score_submitted.connect(_on_score_submitted)
	
	# Solo enviamos al servidor cuando sea Modo Arcade
	if GlobalState.current_mode == GlobalState.Mode.ARCADE:
		status_label.text = "Enviando récord de Arcade al servidor..."
		NetworkBridge.submit_match_score("udoware", GlobalState.score, 3)
	else:
		status_label.text = "Modo Historia."

#Cuando se envie el puntaje
func _on_score_submitted(success: bool, _code: int, message: String) -> void:
	#Se actualiza segun el mensaje que le llegue de la señal
	#Definido en el network bridge
	status_label.text = message

#Cuando se presiona reintentar
func _on_retry_pressed() -> void:
	GlobalState.reset_run()
	get_tree().change_scene_to_file("res://core/runner/microgame_runner.tscn")

#Cuando se presiona menu
func _on_menu_pressed() -> void:
	GlobalState.reset_run()
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")
