extends MicrogameBase

@onready var tickle_zone: ColorRect = $GameplayArea/TickleZone
@onready var indicator_label: Label = $GameplayArea/TickleZone/IndicatorLabel

var tickle_progress: float = 0.0
const TARGET_RUB_DISTANCE: float = 1400.0
var base_pos: Vector2

func _ready() -> void:
	super._ready()
	# Posición aleatoria en pantalla
	base_pos = Vector2(randf_range(100.0, 520.0), randf_range(100.0, 380.0))
	tickle_zone.position = base_pos

func _input(event: InputEvent) -> void:
	if is_finished: return
	if event is InputEventMouseMotion:
		if tickle_zone.get_global_rect().has_point(event.position):
			tickle_progress += event.relative.length()
			# Efecto de risa/temblor en la zona
			tickle_zone.position = base_pos + Vector2(randf_range(-6, 6), randf_range(-6, 6))
			
			var pct: int = clampi(int((tickle_progress / TARGET_RUB_DISTANCE) * 100.0), 0, 100)
			indicator_label.text = "¡JAJAJA! (%d%%)" % pct
			
			if tickle_progress >= TARGET_RUB_DISTANCE:
				tickle_zone.modulate = Color.GREEN
				win()
