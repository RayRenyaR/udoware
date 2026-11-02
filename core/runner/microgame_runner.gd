#Microgame runner
#El corazon del juego

extends Node2D

#Enums
enum State { 
	 INTERMISSION, #Periodo donde se muestran las vidas y puntos
	 PRE_GAME_PROMPT, #Muestra la accion del juego
	 PLAYING, #Jugando
	 EVALUATION, #Decide si se gano o perdio
	 CHECK_PROGRESSION, #Revisa si viene jefe o acelerar velocidad
	 GAME_OVER # PErdiste lol
	}

#Constantes
const WINS_UNTIL_SPEEDUP: int = 5

#Variables
var current_state: State = State.INTERMISSION

var current_game_data: MicrogameData
var current_game_instance: MicrogameBase
var current_game_won: bool = false
var games_played_in_current_speed: int = 0

#Referencias
@onready var viewport: Node2D = $MicrogameViewport

	#UI Principal
@onready var intermission_layer: CanvasLayer = $IntermissionLayer
@onready var lives_container: HBoxContainer = $IntermissionLayer/LivesContainer
@onready var score_counter: RichTextLabel = $IntermissionLayer/ScoreCounter
@onready var status_banner: RichTextLabel = $IntermissionLayer/StatusBanner

	#UI Minijuego
@onready var hud_layer: CanvasLayer = $HUDLayer
@onready var command_label: RichTextLabel = $HUDLayer/CommandLabel
@onready var bomb_timer_bar: TextureProgressBar = $HUDLayer/BombTimerBar

	#Timers
@onready var round_timer: Timer = $RoundTimer
@onready var state_timer: Timer = $StateTimer

#Que sucede cuando se instancia
func _ready() -> void:
	#Se conectan los temporizadores
	round_timer.timeout.connect(_on_round_timeout)
	state_timer.timeout.connect(_on_state_timeout)
	hud_layer.hide()
	change_state(State.INTERMISSION)

#Funcion process
#Esta se ejecuta cada frame
#Justo ahora se utiliza para actaulizar la textura de la bomba
func _process(_delta: float) -> void:
	if current_state == State.PLAYING and not round_timer.is_stopped():
		var percent = (round_timer.time_left / round_timer.wait_time) * 100.0
		bomb_timer_bar.value = percent

#Maquina de estados del juego
func change_state(new_state: State) -> void:
	current_state = new_state
	
	match current_state:
		#ESTADO DE DESCANSO
		State.INTERMISSION:
			#Se muestran las capas de descanso y se esconden las de juego
			intermission_layer.show()
			hud_layer.hide()
			
			#Actualizacion del texto y las vidas
			_update_lives_ui()
			score_counter.text = "[center][shake rate=20.0 level=5 connected=1]%03d[/shake][/center]" % GlobalState.score
			
			#Se selecciona el siguiente juego
			current_game_data = GlobalState.get_next_microgame()
			
			#Si el juego es un jefe, se avisa por el texto
			if current_game_data and current_game_data.is_boss:
				status_banner.text = "[center][shake rate=40 level=15]¡NIVEL JEFE![/shake][/center]"
			#Si no un preparate normal
			else:
				status_banner.text = "[center]¡PREPÁRATE![/center]"
			
			#Segundo y medio de descanso
			state_timer.start(1.5)
		
		#PERIODO PARA MOSTRAR LA ACCION
		State.PRE_GAME_PROMPT:
			#Se esconde la pantalla de descanso y se muestra la de juego
			intermission_layer.hide()
			hud_layer.show()
			current_game_won = false
			
			#Se instancia el minijuego
			if current_game_data and current_game_data.scene:
				current_game_instance = current_game_data.scene.instantiate() as MicrogameBase
				# BLOQUEO DE SEGURIDAD: Pausamos el microjuego durante el cartel de orden
				# para que un clic temprano no dispare la señal antes de entrar a PLAYING
				current_game_instance.process_mode = Node.PROCESS_MODE_DISABLED
				viewport.add_child(current_game_instance)
				current_game_instance.microgame_finished.connect(_on_microgame_finished)
			
			#Configuracion de la textura de bomba
			#Y se configura el texto de accion
			bomb_timer_bar.value = 100
			var cmd = current_game_data.command_text if current_game_data else "¡JUEGA!"
			command_label.text = "[center][wave amp=50.0 freq=10.0 connected=1]%s[/wave][/center]" % cmd
			
			#Un segundo para mostrar la accion
			state_timer.start(1.0)
		
		#JUGANDO
		State.PLAYING:
			#Limpiamos el texto
			command_label.text = ""
			# DESBLOQUEAMOS el microjuego justo cuando empieza a correr el tiempo
			if current_game_instance:
				current_game_instance.process_mode = Node.PROCESS_MODE_INHERIT
				
			var duration = current_game_data.base_duration if current_game_data else 4.0
			round_timer.start(duration)
		
		#Evaluacion
		State.EVALUATION:
			#Se muestra la pantalla de intermision
			round_timer.stop()
			intermission_layer.show()
			hud_layer.hide()
			
			#Liberamos el juego para q no consuma memoria
			if is_instance_valid(current_game_instance):
				current_game_instance.queue_free()
				current_game_instance = null
			
			#Si ganamos añadimos las victorias
			if current_game_won:
				GlobalState.score += 1
				games_played_in_current_speed += 1
				#Si es modo historia llevamos la cuenta para saber cuando cambiar al jefe
				if GlobalState.current_mode == GlobalState.Mode.STORY:
					GlobalState.story_Wins_in_current_stage += 1
				status_banner.text = "[center][rainbow]¡BIEN![/rainbow][/center]"
			else:
				GlobalState.lives -= 1
				status_banner.text = "[center][shake rate=50 level=20]¡MAL![/shake][/center]"
			
			#actualizamos la interfaz
			_update_lives_ui()
			score_counter.text = "[center][shake rate=20.0 level=5 connected=1]%03d[/shake][/center]" % GlobalState.score
			
			#Segundo y medio para evaluar el resultado (despues de esto vendria el de descanso)
			state_timer.start(1.5)
		
		#Revision
		State.CHECK_PROGRESSION:
			# Si se perdieron todas las vidas es gameover
			if GlobalState.lives <= 0:
				change_state(State.GAME_OVER)
				return
			
			#Si completo los minijuegos del modo historia ov vencio al jefe
			if GlobalState.current_mode == GlobalState.Mode.STORY:
				var beat_boss: bool = current_game_won and current_game_data and current_game_data.is_boss
				var completed_5_games: bool = (GlobalState.story_Wins_in_current_stage >= 5)
				
				if beat_boss or completed_5_games:
					GlobalState.speed_scale = 1.0 # Restaurar velocidad normal para la cinematica
					GlobalState.current_cutscene_type = GlobalState.CutsceneType.OUTRO
					get_tree().change_scene_to_file("res://ui/cutscenes/cutscene_player.tscn")
					return
			
			# Aumentar velocidad si ya jugo suficientes minijuegos
			if games_played_in_current_speed >= WINS_UNTIL_SPEEDUP:
				games_played_in_current_speed = 0
				GlobalState.speed_scale += 0.15
				status_banner.text = "[center][wave]¡MÁS RÁPIDO![/wave][/center]"
				
				#Segundo y medio para mostrar si hay q ir mas rapido
				state_timer.start(1.5)
			else:
				change_state(State.INTERMISSION)
		
		#Si perdiste
		State.GAME_OVER:
			status_banner.text = "[center]GAME OVER[/center]"
			GlobalState.speed_scale = 1.0
			#Cambiamos a la escena de gameover
			get_tree().change_scene_to_file("res://ui/game_over/game_over.tscn")

# Receptores de señaes

#Cuando se acaba un minijuego
func _on_microgame_finished(won: bool) -> void:
	#Si el estado actual es jugando o accion (q no deberia, pero asi se evitan errores en caso de que lo resuelva antes de q lo procese)
	if current_state == State.PLAYING or current_state == State.PRE_GAME_PROMPT:
		current_game_won = won
		change_state(State.EVALUATION)

#Cuando se acaba el tiempo del minijuego
func _on_round_timeout() -> void:
	if current_state == State.PLAYING and is_instance_valid(current_game_instance):
		#Se llama a la funcion del minijuego
		current_game_instance.on_time_up()

#Manejo del temporizador de estados
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


#Manejo de los visuales de las vidas
func _update_lives_ui() -> void:
	var hearts = lives_container.get_children()
	for i in range(hearts.size()):
		if i < GlobalState.lives:
			hearts[i].modulate = Color.WHITE
		else:
			hearts[i].modulate = Color(0.2, 0.2, 0.2, 0.5)
