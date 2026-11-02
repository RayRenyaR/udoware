extends Node2D

enum State { INTERMISSION, PRE_GAME_PROMPT, PLAYING, EVALUATION, CHECK_PROGRESSION, GAME_OVER }
var current_state: State = State.INTERMISSION

var current_game_data: MicrogameData
var current_game_instance: MicrogameBase
var current_game_won: bool = false
var games_played_in_current_speed: int = 0

@onready var viewport: Node2D = $MicrogameViewport

@onready var intermission_layer: CanvasLayer = $IntermissionLayer
@onready var lives_container: HBoxContainer = $IntermissionLayer/LivesContainer
@onready var score_counter: RichTextLabel = $IntermissionLayer/ScoreCounter
@onready var status_banner: RichTextLabel = $IntermissionLayer/StatusBanner

@onready var hud_layer: CanvasLayer = $HUDLayer
@onready var command_label: RichTextLabel = $HUDLayer/CommandLabel
@onready var bomb_timer_bar: TextureProgressBar = $HUDLayer/BombTimerBar

@onready var round_timer: Timer = $RoundTimer
@onready var state_timer: Timer = $StateTimer

func _ready() -> void:
	round_timer.timeout.connect(_on_round_timeout)
	state_timer.timeout.connect(_on_state_timeout)
	hud_layer.hide()
	change_state(State.INTERMISSION)

func _process(_delta: float) -> void:
	if current_state == State.PLAYING and not round_timer.is_stopped():
		var percent = (round_timer.time_left / round_timer.wait_time) * 100.0
		bomb_timer_bar.value = percent

func change_state(new_state: State) -> void:
	current_state = new_state
	
	match current_state:
		State.INTERMISSION:
			intermission_layer.show()
			hud_layer.hide()
			_update_lives_ui()
			
			score_counter.text = "[center][shake rate=20.0 level=5 connected=1]%03d[/shake][/center]" % GlobalState.score
			current_game_data = GlobalState.get_next_microgame()
			
			if current_game_data and current_game_data.is_boss:
				status_banner.text = "[center][shake rate=40 level=15]¡NIVEL JEFE![/shake][/center]"
			else:
				status_banner.text = "[center]¡PREPÁRATE![/center]"
			
			state_timer.start(1.5)
			
		State.PRE_GAME_PROMPT:
			intermission_layer.hide()
			hud_layer.show()
			current_game_won = false
			
			if current_game_data and current_game_data.scene:
				current_game_instance = current_game_data.scene.instantiate() as MicrogameBase
				# BLOQUEO DE SEGURIDAD: Pausamos el microjuego durante el cartel de orden
				# para que un clic temprano no dispare la señal antes de entrar a PLAYING
				current_game_instance.process_mode = Node.PROCESS_MODE_DISABLED
				viewport.add_child(current_game_instance)
				current_game_instance.microgame_finished.connect(_on_microgame_finished)
			
			bomb_timer_bar.value = 100
			var cmd = current_game_data.command_text if current_game_data else "¡JUEGA!"
			command_label.text = "[center][wave amp=50.0 freq=10.0 connected=1]%s[/wave][/center]" % cmd
			
			state_timer.start(1.0)
			
		State.PLAYING:
			command_label.text = ""
			# DESBLOQUEAMOS el microjuego justo cuando empieza a correr el tiempo
			if current_game_instance:
				current_game_instance.process_mode = Node.PROCESS_MODE_INHERIT
				
			var duration = current_game_data.base_duration if current_game_data else 4.0
			round_timer.start(duration)
			
		State.EVALUATION:
			round_timer.stop()
			intermission_layer.show()
			hud_layer.hide()
			
			if is_instance_valid(current_game_instance):
				current_game_instance.queue_free()
				current_game_instance = null
			
			if current_game_won:
				GlobalState.score += 1
				games_played_in_current_speed += 1
				if GlobalState.current_mode == GlobalState.Mode.STORY:
					GlobalState.story_Wins_in_current_stage += 1
				status_banner.text = "[center][rainbow]¡BIEN![/rainbow][/center]"
			else:
				GlobalState.lives -= 1
				status_banner.text = "[center][shake rate=50 level=20]¡MAL![/shake][/center]"
				
			_update_lives_ui()
			score_counter.text = "[center][shake rate=20.0 level=5 connected=1]%03d[/shake][/center]" % GlobalState.score
			state_timer.start(1.5)
			
		State.CHECK_PROGRESSION:
			# 1. ¿Perdió todas las vidas?
			if GlobalState.lives <= 0:
				change_state(State.GAME_OVER)
				return
			
			# 2. ¿Está en Modo Historia y ya completó los 5 juegos (o venció al Jefe)?
			if GlobalState.current_mode == GlobalState.Mode.STORY:
				var beat_boss: bool = current_game_won and current_game_data and current_game_data.is_boss
				var completed_5_games: bool = (GlobalState.story_Wins_in_current_stage >= 5)
				
				if beat_boss or completed_5_games:
					GlobalState.speed_scale = 1.0 # Restaurar velocidad normal para la cinemática
					GlobalState.current_cutscene_type = GlobalState.CutsceneType.OUTRO
					get_tree().change_scene_to_file("res://ui/cutscenes/cutscene_player.tscn")
					return
			
			# 3. ¿Toca Speed Up?
			if games_played_in_current_speed >= 5:
				games_played_in_current_speed = 0
				GlobalState.speed_scale += 0.15
				status_banner.text = "[center][wave]¡MÁS RÁPIDO![/wave][/center]"
				state_timer.start(1.5)
			else:
				change_state(State.INTERMISSION)
				
		State.GAME_OVER:
			status_banner.text = "[center]GAME OVER[/center]"
			GlobalState.speed_scale = 1.0
			# Añade un pequeño Timer o cambia de escena de inmediato
			get_tree().change_scene_to_file("res://ui/game_over/game_over.tscn")
# --- SEÑALES ---

func _on_microgame_finished(won: bool) -> void:
	print("Señal recibida del microjuego -> Ganó: ", won, " | Estado actual: ", current_state)
	# Ahora aceptamos la señal y pasamos directo a evaluación
	if current_state == State.PLAYING or current_state == State.PRE_GAME_PROMPT:
		current_game_won = won
		change_state(State.EVALUATION)

func _on_round_timeout() -> void:
	if current_state == State.PLAYING and is_instance_valid(current_game_instance):
		current_game_instance.on_time_up()

func _on_state_timeout() -> void:
	match current_state:
		State.INTERMISSION:
			change_state(State.PRE_GAME_PROMPT)
		State.PRE_GAME_PROMPT:
			change_state(State.PLAYING)
		State.EVALUATION:
			change_state(State.CHECK_PROGRESSION)
		State.CHECK_PROGRESSION:
			# Este timeout ocurre después del aviso de "¡MÁS RÁPIDO!"
			change_state(State.INTERMISSION)

func _update_lives_ui() -> void:
	var hearts = lives_container.get_children()
	for i in range(hearts.size()):
		if i < GlobalState.lives:
			hearts[i].modulate = Color.WHITE
		else:
			hearts[i].modulate = Color(0.2, 0.2, 0.2, 0.5)
