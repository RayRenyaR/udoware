extends Control

@onready var score_label: RichTextLabel = $ScoreLabel
@onready var status_label: RichTextLabel = $StatusLabel
@onready var http_request: HTTPRequest = $ScoreHTTPRequest

@onready var retry_button: Button = $HBoxContainer/RetryButton
@onready var menu_button: Button = $HBoxContainer/MenuButton

func _ready() -> void:
	# 1. Mostrar puntaje final
	score_label.text = "Rondas Superadas: %d" % GlobalState.score
	
	# 2. Conectar los botones
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# 3. Conectar la respuesta del servidor a nuestra función
	http_request.request_completed.connect(_on_request_completed)
	
	# 4. Enviar datos
	_send_score_to_server()
	_notify_react_iframe()

func _on_retry_pressed() -> void:
	GlobalState.reset_run()
	get_tree().change_scene_to_file("res://core/runner/microgame_runner.tscn")

func _on_menu_pressed() -> void:
	# Reseteamos por si acaso, aunque main_menu no arranca partida directa
	GlobalState.reset_run()
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")

func _send_score_to_server() -> void:
	if GlobalState.score == 0:
		status_label.text = "Puntaje en 0. No se envía al servidor."
		return
		
	status_label.text = "Enviando puntuación al servidor..."
	
	# Preparamos el cuerpo de la petición (Payload)
	var body: String = JSON.stringify({
		"game_id": "udoware",
		"score": GlobalState.score,
		"mode": GlobalState.current_mode,
		"story": GlobalState.current_story_id
	})
	
	# Cabecera indispensable para Spring Boot
	var headers: PackedStringArray = ["Content-Type: application/json"]
	
	# Ejecutamos el POST hacia la ruta definida en el MVP para guardar el puntaje[cite: 3]
	var err = http_request.request("http://localhost:8080/api/scores", headers, HTTPClient.Method.METHOD_POST, body)
	
	if err != OK:
		status_label.text = "Error interno al preparar la conexión HTTP."

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if response_code == 200 or response_code == 201:
		status_label.text = "¡Puntuación guardada en el Ranking competitivo!"
	else:
		# Al probar en local sin prender Spring Boot, caerá aquí
		status_label.text = "Modo local: Servidor inactivo (Código: %d)" % response_code

func _notify_react_iframe() -> void:
	# OS.has_feature("web") asegura que esto solo se ejecute cuando el juego corre en HTML5
	if OS.has_feature("web"):
		# Inyectamos código JS para enviarle el evento al React (App Shell)
		var js_code = """
			window.parent.postMessage({
				type: 'GAME_OVER',
				score: %d,
				game: 'udoware'
			}, '*');
		""" % GlobalState.score
		JavaScriptBridge.eval(js_code)
