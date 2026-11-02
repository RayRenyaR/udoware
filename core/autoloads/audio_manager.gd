#AUDIO MANAGER
#Script global que se encarga de la musica y sfx del juego
extends Node

var bgm_player: AudioStreamPlayer 
var current_pitch: float = 1.0

#Accion apenas se instancia el script
func _ready() -> void:
	bgm_player = AudioStreamPlayer.new() #Se invoca un nuevo reproductor
	bgm_player.bus = &"Music" #Se asigna al bus de musica
	add_child(bgm_player) #Se agrega al arbol como bgm_player

#Funcion para poner musica
func play_bgm(stream: AudioStream, custom_volume_db: float = 0.0) -> void:
	#Si ya se esta reproduciendo la misma peticion se ignora
	if bgm_player.stream == stream and bgm_player.playing:
		return
	#Configuracion del audio, volumen y pitch
	bgm_player.stream = stream
	bgm_player.volume_db = custom_volume_db
	bgm_player.pitch_scale = current_pitch
	bgm_player.play()

#Funcion para detener la musica
func stop_bgm() -> void:
	bgm_player.stop()

#Reproducir efecto de sonido
#Lo que hace es instancear varios reproductores de audio
#Y los elimina apenas terminan de reproducirse
func play_sfx(stream: AudioStream, custom_volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var sfx = AudioStreamPlayer.new()
	sfx.bus = &"SFX"
	sfx.stream = stream
	sfx.volume_db = custom_volume_db
	sfx.pitch_scale = current_pitch
	add_child(sfx)
	sfx.play()
	# Se autodestruye automaticamente apenas termina de sonar
	sfx.finished.connect(sfx.queue_free)

#Funcion para actualizar el pitch de la musica
func update_pitch(speed: float) -> void:
	current_pitch = 1.0 + (speed - 1.0) * 0.5
	if bgm_player:
		bgm_player.pitch_scale = current_pitch
