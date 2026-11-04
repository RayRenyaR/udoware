extends MicrogameBase

@onready var cut_guide: ColorRect = $GameplayArea/CutGuide
@onready var cut_label: Label = $GameplayArea/CutLabel

const TARGET_CUTS: int = 6
var current_cuts: int = 0
var moving_down: bool = true
var vertical_accum: float = 0.0
const STROKE_THRESHOLD: float = 90.0 # Píxeles verticales por cada pasada

func _ready() -> void:
	super._ready()
	# Coloca la guía en una posición horizontal aleatoria
	cut_guide.position = Vector2(randf_range(160.0, 540.0), 140.0)
	_update_ui()

func _input(event: InputEvent) -> void:
	if is_finished: return
	if event is InputEventMouseMotion:
		if cut_guide.get_global_rect().has_point(event.position):
			var dy: float = event.relative.y
			if (moving_down and dy > 0.0) or (not moving_down and dy < 0.0):
				vertical_accum += absf(dy)
				if vertical_accum >= STROKE_THRESHOLD:
					vertical_accum = 0.0
					moving_down = not moving_down
					current_cuts += 1
					shake_camera(4.0, 0.06)
					_update_ui()
					
					if current_cuts >= TARGET_CUTS:
						cut_guide.modulate = Color.GREEN
						win()

func _update_ui() -> void:
	var dir_arrow: String = "⬇ BAJA" if moving_down else "⬆ SUBE"
	cut_label.text = "¡CORTA AQUÍ!\n%s (%d/%d)" % [dir_arrow, current_cuts, TARGET_CUTS]
