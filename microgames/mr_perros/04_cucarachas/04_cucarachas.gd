extends MicrogameBase

var hits_needed: int = 2
var velocity: Vector2 = Vector2(380, 290)
var dir_timer: float = 0.0

@onready var roach_btn: Button = $GameplayArea/RoachButton

func _ready() -> void:
	super._ready()
	roach_btn.position = Vector2(350, 250)
	roach_btn.pressed.connect(_on_roach_hit)

func _process(delta: float) -> void:
	if is_finished: return
	
	roach_btn.position += velocity * delta
	
	# Rebote en los bordes de la pantalla (asumiendo 800x600 o similar)
	if roach_btn.position.x < 40 or roach_btn.position.x > 660:
		velocity.x *= -1
	if roach_btn.position.y < 60 or roach_btn.position.y > 460:
		velocity.y *= -1
		
	# Cambio de dirección en zigzag cada 0.45 segundos
	dir_timer += delta
	if dir_timer >= 0.45:
		dir_timer = 0.0
		velocity = velocity.rotated(deg_to_rad(randf_range(-75, 75)))

func _on_roach_hit() -> void:
	if is_finished: return
	hits_needed -= 1
	shake_camera(10.0, 0.15)
	
	if hits_needed == 1:
		roach_btn.text = "🪳 ¡Ay! (Falta 1)"
		roach_btn.modulate = Color.ORANGE
		velocity *= 1.35 # Corre más rápido tras el primer chancletazo
	elif hits_needed <= 0:
		roach_btn.text = "💀 ¡PLAF!"
		roach_btn.disabled = true
		win()
