extends MicrogameBase

const TARGET_CLICKS: int = 10
var clicks: int = 0
var start_y: float = 80.0
var goal_y: float = 420.0

@onready var water_btn: Button = $GameplayArea/WaterButton
@onready var pill: Control = $GameplayArea/PillRect

func _ready() -> void:
	super._ready()
	pill.position.y = start_y
	water_btn.pressed.connect(_on_water_clicked)

func _on_water_clicked() -> void:
	if is_finished: return
	clicks += 1
	
	# Avanza proporcionalmente hacia el esófago
	var progress: float = float(clicks) / float(TARGET_CLICKS)
	pill.position.y = lerpf(start_y, goal_y, progress)
	water_btn.text = "💧 ¡Traga! (%d/%d)" % [clicks, TARGET_CLICKS]
	shake_camera(4.0, 0.05)
	
	if clicks >= TARGET_CLICKS:
		win()
