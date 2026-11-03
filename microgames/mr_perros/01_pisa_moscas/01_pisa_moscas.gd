#01 PISA MOSCAS
#Pisa a las moscas
extends MicrogameBase

var flies_left: int = 3
@onready var flies: Array[Button] = [$GameplayArea/Fly1, $GameplayArea/Fly2, $GameplayArea/Fly3]

#Cuando se inicia
func _ready() -> void:
	super._ready()
	for fly in flies:
		# Posicion aleatoria inicial dentro de un margen seguro
		fly.position = Vector2(randf_range(100, 650), randf_range(100, 420))
		fly.pressed.connect(_on_fly_squashed.bind(fly))

func _process(delta: float) -> void:
	if is_finished: return
	# Pequeño temblor para simular el zumbido de las moscas vivas
	for fly in flies:
		if not fly.disabled:
			fly.position += Vector2(randf_range(-60, 60), randf_range(-60, 60)) * delta
			fly.position = fly.position.clamp(Vector2(60, 60), Vector2(700, 460))

func _on_fly_squashed(fly: Button) -> void:
	if is_finished: return
	fly.disabled = true
	fly.text = "¡PLAF!"
	fly.modulate = Color.GREEN # Simula la mancha verde
	shake_camera(5.0, 0.1)
	
	flies_left -= 1
	if flies_left <= 0:
		win()
