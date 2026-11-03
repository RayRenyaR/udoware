extends MicrogameBase

const TARGET_CLICKS: int = 8
var current_clicks: int = 0

@onready var clicker_btn: Button = $GameplayArea/ClickerButton
@onready var lead_tip: ColorRect = $GameplayArea/LeadTip

func _ready() -> void:
	super._ready()
	clicker_btn.pressed.connect(_on_clicker_pressed)
	_update_ui()

func _on_clicker_pressed() -> void:
	if is_finished: return
	current_clicks += 1
	lead_tip.size.y += 18 # La mina crece hacia abajo con cada clic
	shake_camera(3.0, 0.05)
	_update_ui()
	
	if current_clicks >= TARGET_CLICKS:
		win()

func _update_ui() -> void:
	clicker_btn.text = "¡CLIC! (%d/%d)" % [current_clicks, TARGET_CLICKS]
