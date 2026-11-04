extends MicrogameBase

@onready var flashlight: ColorRect = $GameplayArea/Flashlight
@onready var monster: ColorRect = $GameplayArea/Monster
@onready var status_label: Label = $GameplayArea/StatusLabel

const TOTAL_MONSTERS: int = 4
const LIGHT_RADIUS: float = 85.0
const EXPOSE_TIME_NEEDED: float = 0.45
const MONSTER_ATTACK_TIME: float = 2.4

var monsters_left: int = TOTAL_MONSTERS
var current_expose_time: float = 0.0
var attack_timer: float = MONSTER_ATTACK_TIME

func _ready() -> void:
	super._ready()
	_spawn_next_monster()

func _process(delta: float) -> void:
	if is_finished: return
	
	var mouse_pos: Vector2 = get_global_mouse_position()
	flashlight.global_position = mouse_pos - (flashlight.size * 0.5)
	
	var monster_center: Vector2 = monster.global_position + (monster.size * 0.5)
	var dist: float = mouse_pos.distance_to(monster_center)
	
	# Si la linterna apunta al monstruo, se vuelve visible y se espanta
	if dist <= LIGHT_RADIUS:
		monster.modulate.a = 1.0
		current_expose_time += delta
		monster.position += Vector2(randf_range(-4, 4), randf_range(-4, 4)) # Tiembla al ser alumbrado
		if current_expose_time >= EXPOSE_TIME_NEEDED:
			shake_camera(6.0, 0.1)
			monsters_left -= 1
			if monsters_left <= 0:
				monster.hide()
				status_label.text = "¡TODOS LOS MONSTRUOS ESPANTADOS!"
				win()
			else:
				_spawn_next_monster()
	else:
		# Oculto en la oscuridad mientras avanza su temporizador de ataque
		monster.modulate.a = 0.03
		attack_timer -= delta
		if attack_timer <= 0.0:
			monster.modulate = Color.RED
			monster.modulate.a = 1.0
			status_label.text = "¡TE ATACÓ EN LA OSCURIDAD!"
			shake_camera(15.0, 0.3)
			lose()
			
	if not is_finished and monsters_left > 0:
		status_label.text = "Monstruos restantes: %d | ¡Ataque en: %.1fs!" % [monsters_left, maxf(0.0, attack_timer)]

func _spawn_next_monster() -> void:
	current_expose_time = 0.0
	attack_timer = MONSTER_ATTACK_TIME
	monster.position = Vector2(randf_range(80.0, 640.0), randf_range(90.0, 440.0))
	monster.modulate.a = 0.03
