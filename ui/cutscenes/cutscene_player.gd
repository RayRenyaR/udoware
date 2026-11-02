extends Control

@onready var dialogue_box: RichTextLabel = $DialogueBox
@onready var next_button: Button = $NextButton
# Si ya agregaste un AnimationPlayer a la escena, puedes referenciarlo con:
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

# Diccionario de guiones por historia (Intro y Outro) + nombre de animación opcional para el futuro
var story_scripts: Dictionary = {
	"historia_1": {
		GlobalState.CutsceneType.INTRO: [
			{"text": "[wave]HISTORIA 1 (INTRO):[/wave] ¡Plaga de moscas mutantes en el comedor!", "anim": "intro_step_1"},
			{"text": "Prepara el dedo índice... ¡Hay que aplastarlas a puros clics!", "anim": "intro_step_2"}
		],
		GlobalState.CutsceneType.OUTRO: [
			{"text": "[rainbow]HISTORIA 1 (FINAL):[/rainbow] ¡Exterminaste a la mosca reina!", "anim": "outro_step_1"},
			{"text": "El comedor vuelve a ser medianamente salubre. ¡Historia completada!", "anim": "outro_step_2"}
		]
	},
	"historia_2": {
		GlobalState.CutsceneType.INTRO: [
			{"text": "[wave]HISTORIA 2 (INTRO):[/wave] ¡El salón está lleno de suciedad paranormal!", "anim": "intro_step_1"},
			{"text": "¡Mueve el ratón a toda velocidad para limpiar el desastre!", "anim": "intro_step_2"}
		],
		GlobalState.CutsceneType.OUTRO: [
			{"text": "[rainbow]HISTORIA 2 (FINAL):[/rainbow] ¡Quedó tan limpio que encandila!", "anim": "outro_step_1"}
		]
	},
	"historia_3": {
		GlobalState.CutsceneType.INTRO: [
			{"text": "[wave]HISTORIA 3 (INTRO):[/wave] ¡Faltan 2 minutos para entregar el código!", "anim": "intro_step_1"},
			{"text": "¡Golpea las teclas exactas antes de que explote la PC!", "anim": "intro_step_2"}
		],
		GlobalState.CutsceneType.OUTRO: [
			{"text": "[rainbow]HISTORIA 3 (FINAL):[/rainbow] ¡El commit entró a las 11:59:59 PM!", "anim": "outro_step_1"}
		]
	}
}

var current_slides: Array = []
var current_index: int = 0

func _ready() -> void:
	Engine.time_scale = 1.0
	next_button.pressed.connect(_on_next_pressed)
	
	# Cargar el guion según la historia y si es Intro o Final
	var story_id = GlobalState.current_story_id
	var c_type = GlobalState.current_cutscene_type
	
	if story_scripts.has(story_id) and story_scripts[story_id].has(c_type):
		current_slides = story_scripts[story_id][c_type]
	else:
		current_slides = [{"text": "Cinemática de prueba...", "anim": ""}]
		
	_show_step(0)

func _show_step(index: int) -> void:
	if index >= current_slides.size():
		_finish_cutscene()
		return
		
	var step_data: Dictionary = current_slides[index]
	dialogue_box.text = "[center]" + step_data.get("text", "") + "[/center]"
	
	# Cuando diseñes las animaciones en el AnimationPlayer, se dispararán solas aquí:
	var anim_name: String = step_data.get("anim", "")
	if anim_player and anim_name != "" and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)

func _on_next_pressed() -> void:
	current_index += 1
	_show_step(current_index)

func _finish_cutscene() -> void:
	if GlobalState.current_cutscene_type == GlobalState.CutsceneType.INTRO:
		# Si terminó la Intro, arrancamos los microjuegos de esa historia
		get_tree().change_scene_to_file("res://core/runner/microgame_runner.tscn")
	else:
		# Si terminó el Outro (venció al jefe), regresamos al selector de historias
		get_tree().change_scene_to_file("res://ui/story_select/story_select.tscn")
