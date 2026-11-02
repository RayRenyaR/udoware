#NETWORK BRIDGE
#Script global encargado de la comunicacion con el backend SpringBoot
extends Node

#Señales
signal score_submitted(success: bool, response_code: int, message: String)

#Direccion del backend, actualizar si se despliega en railway
@export var api_base_url: String = "http://localhost:8080/api"

#Objeto http nativo de godot
var _http: HTTPRequest
var _is_busy: bool = false

#Ejecucion al instanciarse
func _ready() -> void:
	#Se crea un objeto http con 10 segundos de timeout y se agrega como hijo
	_http = HTTPRequest.new()
	_http.timeout = 10.0
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

#Enviar puntaje
func submit_match_score(game_alias: String, points: int, user_id: int = 3) -> void:
	# Notificar a React (si corre dentro de la web)
	_notify_web_wrapper(game_alias, points)
	
	if points <= 0:
		score_submitted.emit(false, 0, "Puntaje en 0, no se envía al servidor.")
		return
		
	if _is_busy:
		score_submitted.emit(false, 0, "Petición en curso, espera un momento.")
		return

	#Informacion a enviar
	var payload: Dictionary = {
		"gameAlias": game_alias,
		"userId": user_id,
		"score": points,
	}
	
	#Cabezera necesaria para que sepa q recibira un json
	var headers: PackedStringArray = ["Content-Type: application/json"]
	_is_busy = true
	
	#Se realiza la peticion
	var err: Error = _http.request(api_base_url + "/scores/match", headers, HTTPClient.Method.METHOD_POST, JSON.stringify(payload))
	
	#Si da error
	if err != OK:
		_is_busy = false
		score_submitted.emit(false, 0, "Error interno de red en Godot.")

#Funcion para avisarle a react que actualice la pagina
func _notify_web_wrapper(game_alias: String, points: int) -> void:
	#Revisa si esta corriendo en web
	if OS.has_feature("web"):
		var js_code: String = """
			window.parent.postMessage({
				type: 'GAME_OVER',
				game: '%s',
				score: %d,
			}, '*');
		""" % [game_alias, points]
		JavaScriptBridge.eval(js_code)

#Cuando termine la solicitud devuelve una señal con la respuesta 
func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_is_busy = false
	var response_text: String = body.get_string_from_utf8()
	
	if response_code >= 200 and response_code < 300:
		score_submitted.emit(true, response_code, "¡Récord guardado en el Ranking!")
	else:
		score_submitted.emit(false, response_code, "Error del servidor (Código %d): %s" % [response_code, response_text])
