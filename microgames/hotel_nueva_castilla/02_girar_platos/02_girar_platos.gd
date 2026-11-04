extends MicrogameBase

@onready var rub_zone: ColorRect = $GameplayArea/RubZone
@onready var plate: ColorRect = $GameplayArea/Plate

var spin_energy: float = 80.0 # Si llega a 0, el plato se cae
const DECAY_RATE: float = 48.0

func _ready() -> void:
	super._ready()
	win_on_timeout = true # Gana al sobrevivir los 4 segundos

func _process(delta: float) -> void:
	if is_finished: return
	
	spin_energy -= DECAY_RATE * delta
	
	# Efecto visual de giro y tambaleo cuando pierde velocidad
	var wobble: float = (100.0 - clampf(spin_energy, 0.0, 100.0)) * 0.35
	plate.rotation_degrees = sin(Time.get_ticks_msec() * 0.03) * wobble
	
	if spin_energy <= 0.0:
		# El plato cae y pierdes
		plate.position.y += 250
		plate.modulate = Color.RED
		shake_camera(10.0, 0.2)
		lose()

func _input(event: InputEvent) -> void:
	if is_finished: return
	if event is InputEventMouseMotion:
		# Verifica que el jugador esté frotando en el área inferior debajo del palo
		if rub_zone.get_global_rect().has_point(event.position):
			spin_energy = minf(100.0, spin_energy + absf(event.relative.x) * 0.14)
