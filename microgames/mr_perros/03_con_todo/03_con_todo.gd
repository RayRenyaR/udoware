extends MicrogameBase

@onready var order_label: RichTextLabel = $GameplayArea/OrderLabel
@onready var buttons: Dictionary = {
	"Tomate": $GameplayArea/BtnKetchup,
	"Mostaza": $GameplayArea/BtnMustard,
	"Mayo": $GameplayArea/BtnMayo,
	"Tartara": $GameplayArea/BtnTartara
}

var target_sauces: Array[String] = []
var selected_sauces: Array[String] = []

func _ready() -> void:
	super._ready()
	var all_keys: Array = buttons.keys()
	all_keys.shuffle()
	
	# El cliente pide 2 salsas al azar
	target_sauces = [all_keys[0], all_keys[1]]
	order_label.text = "[center]¡Dame [b]%s[/b] y [b]%s[/b]![/center]" % [target_sauces[0], target_sauces[1]]
	
	for sauce_name in buttons:
		var btn: Button = buttons[sauce_name]
		btn.pressed.connect(_on_sauce_clicked.bind(sauce_name, btn))

func _on_sauce_clicked(sauce_name: String, btn: Button) -> void:
	if is_finished: return
	btn.disabled = true
	
	# Si eligió una salsa que el cliente NO pidió, pierde al instante
	if not target_sauces.has(sauce_name):
		btn.modulate = Color.RED
		shake_camera(12.0, 0.25)
		lose()
		return
		
	btn.modulate = Color.GREEN
	selected_sauces.append(sauce_name)
	
	# Si ya seleccionó las 2 correctas, gana
	if selected_sauces.size() == target_sauces.size():
		win()
