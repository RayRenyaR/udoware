extends MicrogameBase

@onready var direction_label: Label = $GameplayArea/DirectionLabel
@onready var disc: ColorRect = $GameplayArea/Disc

var target_dir: int = 1 # 1 = Derecha (Horario), -1 = Izquierda (Antihorario)
var accumulated_angle: float = 0.0
const TARGET_RADIANS: float = TAU * 2.5 # 2 vueltas y media para ganar
var last_mouse_angle: float = 0.0

func _ready() -> void:
	super._ready()
	disc.pivot_offset = disc.size * 0.5
	target_dir = 1 if randf() > 0.5 else -1
	
	if target_dir == 1:
		direction_label.text = "¡GIRA EN CÍRCULOS A LA DERECHA (↻)!"
	else:
		direction_label.text = "¡GIRA EN CÍRCULOS A LA IZQUIERDA (↺)!"
		
	var center: Vector2 = disc.global_position + disc.pivot_offset
	last_mouse_angle = (get_global_mouse_position() - center).angle()

func _input(event: InputEvent) -> void:
	if is_finished: return
	if event is InputEventMouseMotion:
		var center: Vector2 = disc.global_position + disc.pivot_offset
		var current_angle: float = (event.position - center).angle()
		var delta_angle: float = angle_difference(last_mouse_angle, current_angle)
		last_mouse_angle = current_angle
		
		# Comprobar si gira en el sentido pedido
		if delta_angle * target_dir > 0.0:
			accumulated_angle += absf(delta_angle)
			disc.rotation += delta_angle
			
			if accumulated_angle >= TARGET_RADIANS:
				direction_label.text = "¡MEZCLA PERFECTA!"
				disc.modulate = Color.GREEN
				win()
