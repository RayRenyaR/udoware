#SCRIPT DE ESTADO GLOBAL
#Controla datos generales y el estado global del juego
extends Node

#Constantes
const WINS_UNTIL_BOSS : int = 15

#Enums
enum Mode { STORY, ARCADE }
enum CutsceneType { INTRO, OUTRO }

#Variables
var current_mode: Mode = Mode.ARCADE
var current_story_id: String = "historia_1"
var current_cutscene_type: CutsceneType = CutsceneType.INTRO

var lives: int = 4
var score: int = 0
var story_Wins_in_current_stage: int = 0 

#Speedscale es para cambiar la velocidad del juego
#Tiene un metodo set que hace que cada vez q esto cambie
#En cualqueir parte del codigo, se ejecute la funcion de abajo
#La cual se asegura que no baje de 0.1, acelera el juego, aumenta el pitch de la musica
var speed_scale: float = 1.0:
	set(value):
		speed_scale = max(0.1, value)
		Engine.time_scale = speed_scale
		if AudioManager:
			AudioManager.update_pitch(speed_scale)

#Registro de minijuegos
#Para que un minijuego quede registrado
#Se debe colocar su data dentro de registryallgame
#Arrastrandose al array dentro de ese archivo
const REGISTRY = preload("res://microgames/registry_all_games.tres")
var last_played_id: String = ""

#Resetear datos
func reset_run() -> void:
	lives = 4
	score = 0
	story_Wins_in_current_stage = 0
	speed_scale = 1.0
	last_played_id = ""

#Seleccionar siguiente minijuego
func get_next_microgame() -> MicrogameData:
	#Si el registro de minijuegos no existe o esta vacio explota
	if REGISTRY == null or REGISTRY.games.is_empty():
		push_warning("GlobalState: El registro de microjuegos está vacío.")
		return null

	var valid_games: Array[MicrogameData] = []
	
	#Si estamos en arcade todos los minijuegos son validos
	if current_mode == Mode.ARCADE:
		valid_games = REGISTRY.games.duplicate()
	else:
		# En Modo Historia: 
		# Se decide si es hora del jefe
		var need_boss: bool = (story_Wins_in_current_stage >= WINS_UNTIL_BOSS)
		
		#Si se necesita el boss se añade solo ese al array de validos
		for game in REGISTRY.games:
			#Si un juego pertenece a una historia
			#Y el juego es un jefe y se necesita un jefe
			if game.story_id == current_story_id and game.is_boss == need_boss:
				#Se añade al array de juegos validos
				valid_games.append(game)
		
		#Si no hay jefe, ahora si revisa y añade todos los minijuegos
		if valid_games.is_empty():
			for game in REGISTRY.games:
				if game.story_id == current_story_id:
					valid_games.append(game)
	
	#Y si aun esta vacio, murio
	if valid_games.is_empty():
		push_warning("GlobalState: No hay juegos para la historia: " + current_story_id)
		return null

	#Sacamos de la lista el ultimo jugado
	if valid_games.size() > 1:
		valid_games = valid_games.filter(func(g): return g.id != last_played_id)
	
	#Se escoge el minijuego
	var chosen: MicrogameData = valid_games.pick_random()
	last_played_id = chosen.id
	return chosen
