extends Node

enum Mode { STORY, ARCADE }
enum CutsceneType { INTRO, OUTRO }

var current_mode: Mode = Mode.ARCADE
var current_story_id: String = "historia_1"
var current_cutscene_type: CutsceneType = CutsceneType.INTRO

var lives: int = 4
var score: int = 0
var story_Wins_in_current_stage: int = 0 # Cuenta cuántos juegos llevas ganados en la historia actual

var speed_scale: float = 1.0:
	set(value):
		speed_scale = max(0.1, value)
		Engine.time_scale = speed_scale
		if AudioManager:
			AudioManager.update_pitch(speed_scale)

const REGISTRY = preload("res://microgames/registry_all_games.tres")
var last_played_id: String = ""

func reset_run() -> void:
	lives = 4
	score = 0
	story_Wins_in_current_stage = 0
	speed_scale = 1.0
	last_played_id = ""

func get_next_microgame() -> MicrogameData:
	if REGISTRY == null or REGISTRY.games.is_empty():
		push_warning("GlobalState: El registro de microjuegos está vacío.")
		return null

	var valid_games: Array[MicrogameData] = []
	
	if current_mode == Mode.ARCADE:
		valid_games = REGISTRY.games.duplicate()
	else:
		# En Modo Historia: los primeros 4 juegos son normales, el 5to (cuando llevas 4 ganados) es el JEFE
		var need_boss: bool = (story_Wins_in_current_stage >= 4)
		
		for game in REGISTRY.games:
			if game.story_id == current_story_id and game.is_boss == need_boss:
				valid_games.append(game)
		
		# Fallback para tus pruebas con Dummies: si aún no has marcado ningún .tres como is_boss = true,
		# toma cualquier juego de esa historia para que no dé error
		if valid_games.is_empty():
			for game in REGISTRY.games:
				if game.story_id == current_story_id:
					valid_games.append(game)
	
	if valid_games.is_empty():
		push_warning("GlobalState: No hay juegos para la historia: " + current_story_id)
		return null

	if valid_games.size() > 1:
		valid_games = valid_games.filter(func(g): return g.id != last_played_id)
	
	var chosen: MicrogameData = valid_games.pick_random()
	last_played_id = chosen.id
	return chosen
