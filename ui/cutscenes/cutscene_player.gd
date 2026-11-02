#CUTSCENE PLAYER
#Dentro de ui/cutscenes
#Se encarga de manejar las animaciones de intro y outro
#Cuando terminan te envia directo al runner
extends Control

@onready var dialogue_box: RichTextLabel = $DialogueBox
@onready var next_button: Button = $NextButton
@onready var anim_player: AnimationPlayer = $AnimationPlayer

#Diccionario de Guiones por historia
#Es un Diccionario anidado
#Es decir, dentro tiene la historia, y dentro de la historia
#Tiene otro diccionario que dice que tipo es y lo q sucede dentro
#Dentro de eso tiene un array que contiene otro diccionario
#Que tiene el texto y la animacion a ejecutar
#Suena mas complejo de lo q es pero es como un monton de gavetas
var story_scripts: Dictionary = {
	"dummy": {
		GlobalState.CutsceneType.INTRO: [
			{"text": "[wave]DUMMY (INTRO):[/wave] CHAMO, ESTO ES UNA PRUEBA!", 
			"anim": "intro_step_1"},
			
			{"text": "TEXTO 2!!! (si, de pana no se me ocurrio nada)",
			 "anim": "intro_step_2"}
		],
		GlobalState.CutsceneType.OUTRO: [
			{"text": "[rainbow]DUMMY (FINAL):[/rainbow] GANASTE", "anim": "outro_step_1"},
			{"text": "y ya.", "anim": "outro_step_2"}
		]
	}
}

#Array y Posicion dentro del guion actual
var current_slides: Array = []
var current_index: int = 0

#Que hace apenas se instancia el script
func _ready() -> void:
	#Velocidad del motor reiniciada
	Engine.time_scale = 1.0
	next_button.pressed.connect(_on_next_pressed)
	
	# Cargar el guion segun la historia y si es Intro o Final
	var story_id = GlobalState.current_story_id
	var c_type = GlobalState.current_cutscene_type
	
	#Si la historia esta en la lista de guiones y esta tiene una intro/outro
	if story_scripts.has(story_id) and story_scripts[story_id].has(c_type):
		#Se toma el arreglo completo
		current_slides = story_scripts[story_id][c_type]
	else:
		current_slides = [{"text": "No se consiguio un guion...", "anim": ""}]
		
	_show_step(0)

#Mostrar parte de la cinematica
func _show_step(index: int) -> void:
	#Si ya se alcanzo el ultimo, se acabo la cinematica
	if index >= current_slides.size():
		_finish_cutscene()
		return
	
	#Se actualiza el texto de la caja de dialogos
	var step_data: Dictionary = current_slides[index]
	dialogue_box.text = "[center]" + step_data.get("text", "") + "[/center]"
	
	# Las animaciones en el AnimationPlayer, se dispararan aqui:
	var anim_name: String = step_data.get("anim", "")
	if anim_player and anim_name != "" and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)

#Cada que se presiona el boton de siguiente
func _on_next_pressed() -> void:
	current_index += 1
	_show_step(current_index)

#Terminar cinematica
func _finish_cutscene() -> void:
	if GlobalState.current_cutscene_type == GlobalState.CutsceneType.INTRO:
		# Si termino la Intro, arrancamos los microjuegos de esa historia
		get_tree().change_scene_to_file("res://core/runner/microgame_runner.tscn")
	else:
		# Si termino el Outro (vencio al jefe), regresamos al selector de historias
		get_tree().change_scene_to_file("res://ui/story_select/story_select.tscn")
