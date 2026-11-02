extends Node2D
class_name MicrogameBase

signal microgame_finished(won: bool)

@export var win_on_timeout: bool = false
var has_won: bool = false
var is_finished: bool = false

@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	has_won = win_on_timeout

func win() -> void:
	if is_finished: return
	has_won = true
	is_finished = true
	microgame_finished.emit(true)

func lose() -> void:
	if is_finished: return
	has_won = false
	is_finished = true
	microgame_finished.emit(false)

func on_time_up() -> void:
	if is_finished: return
	if has_won:
		win()
	else:
		lose()

# Utilidad heredada para todos los 15 microjuegos: sacudir la pantalla sin romper coordenadas
func shake_camera(intensity: float = 8.0, duration: float = 0.2) -> void:
	if not camera: return
	var tween = create_tween()
	var steps = int(duration / 0.04)
	for i in range(steps):
		var random_offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", random_offset, 0.04)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.04)
