extends Node

var bgm_player: AudioStreamPlayer
var current_pitch: float = 1.0

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = &"Music"
	add_child(bgm_player)

func play_bgm(stream: AudioStream, custom_volume_db: float = 0.0) -> void:
	if bgm_player.stream == stream and bgm_player.playing:
		return
	bgm_player.stream = stream
	bgm_player.volume_db = custom_volume_db
	bgm_player.pitch_scale = current_pitch
	bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()

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

func update_pitch(speed: float) -> void:
	current_pitch = 1.0 + (speed - 1.0) * 0.5
	if bgm_player:
		bgm_player.pitch_scale = current_pitch
