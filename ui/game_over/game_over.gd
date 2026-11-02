#GAMEOVER
#Controla la pantalla de perdiste y ademas esta pendiente
#De enviar a la base de datos
extends Control

#Referencias
@onready var score_label: RichTextLabel = $ScoreLabel
@onready var status_label: RichTextLabel = $StatusLabel
@onready var http_request: HTTPRequest = $ScoreHTTPRequest

@onready var retry_button: Button = $HBoxContainer/RetryButton
@onready var menu_button: Button = $HBoxContainer/MenuButton

#Apenas se instancia
func _ready() -> void:
	# Muestra el puntaje final
	score_label.text = "Rondas Superadas: %d" % GlobalState.score
	
	# Conectar los botones
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Conectar la respuesta del servidor a nuestra funcion
	http_request.request_completed.connect(_on_request_completed)
	
	# Enviar datos
	_send_score_to_server()
	_notify_react_iframe()

#Cuando se presiona reiniciar reiniciamos los datos y vamos de nuevo al runner
func _on_retry_pressed() -> void:
	GlobalState.reset_run()
	get_tree().change_scene_to_file("res://core/runner/microgame_runner.tscn")

#Cuando vamos al menu
func _on_menu_pressed() -> void:
	# Reseteamos por si acaso, aunque main_menu no arranca partida directa
	GlobalState.reset_run()
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")

#Enviar puntaje al servidor
func _send_score_to_server() -> void:
	if GlobalState.score == 0:
		status_label.text = "Puntaje en 0. No se envía al servidor."
		return
		
	status_label.text = "Enviando puntuación al servidor..."
	
	# Preparamos el cuerpo de la peticion (Payload)
	var body: String = JSON.stringify({
		"game_id": "udoware",
		"score": GlobalState.score,
		"mode": GlobalState.current_mode,
		"story": GlobalState.current_story_id
	})
	
	# Cabecera para Spring Boot
	#Debido a:
	#Spring Boot utiliza la anotación @RequestBody en sus controladores para mapear automáticamente el cuerpo del mensaje a un objeto Java (usando la librería interna Jackson).
	#Si no envías "Content-Type: application/json", el servidor no sabe cómo interpretar la cadena de texto cruda y rechaza la petición con un error HTTP 415 Unsupported Media Type antes de que el código del controlador llegue a ejecutarse. La cabecera le confirma explícitamente: "los bytes que te estoy enviando representan una estructura JSON válida".
	var headers: PackedStringArray = ["Content-Type: application/json"]
	
	# Ejecutamos el POST hacia la ruta definida en el MVP para guardar el puntaje
	var err = http_request.request("http://localhost:8080/api/scores", headers, HTTPClient.Method.METHOD_POST, body)
	
	if err != OK:
		status_label.text = "Error interno al preparar la conexión HTTP."

#Cuando la peticion se complete
func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if response_code == 200 or response_code == 201:
		status_label.text = "¡Puntuación guardada en el Ranking competitivo!"
	else:
		# Al probar en local sin prender Spring Boot, caera aqui
		status_label.text = "Modo local: Servidor inactivo (Código: %d)" % response_code

#Notificar a react
#ESTO NO LO HE PROBADO Y NO SE SI FUNCIONA
#LO AVERIGUAREMOS xddxdxdx
func _notify_react_iframe() -> void:
	# OS.has_feature("web") asegura que esto solo se ejecute cuando el juego corre en HTML5
	if OS.has_feature("web"):
		# Inyectamos codigo JS para enviarle el evento al React (App Shell)
		var js_code = """
			window.parent.postMessage({
				type: 'GAME_OVER',
				score: %d,
				game: 'udoware'
			}, '*');
		""" % GlobalState.score
		JavaScriptBridge.eval(js_code)
