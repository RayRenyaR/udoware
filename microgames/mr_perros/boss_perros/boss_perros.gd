extends MicrogameBase

enum Phase { OPEN_BREAD, KILL_FLIES, ADD_SAUCE }
var current_phase: Phase = Phase.OPEN_BREAD

var bread_clicks: int = 5
var flies_alive: int = 2
var sauce_clicks: int = 4

@onready var phase_label: RichTextLabel = $GameplayArea/PhaseLabel
@onready var main_btn: Button = $GameplayArea/BossMainBtn
@onready var fly1: Button = $GameplayArea/BossFly1
@onready var fly2: Button = $GameplayArea/BossFly2

func _ready() -> void:
	super._ready()
	main_btn.pressed.connect(_on_main_btn_pressed)
	fly1.pressed.connect(_on_fly_pressed.bind(fly1))
	fly2.pressed.connect(_on_fly_pressed.bind(fly2))
	_setup_phase_1()

func _setup_phase_1() -> void:
	current_phase = Phase.OPEN_BREAD
	phase_label.text = "FASE 1: ¡Abre el pan duro!"
	main_btn.text = "🥖 Pan (Clic x5)"
	fly1.hide()
	fly2.hide()

func _setup_phase_2() -> void:
	current_phase = Phase.KILL_FLIES
	phase_label.text = "FASE 2: ¡Espanta las moscas de la salchicha!"
	main_btn.hide()
	fly1.show()
	fly2.show()

func _setup_phase_3() -> void:
	current_phase = Phase.ADD_SAUCE
	phase_label.text = "FASE 3: ¡Échale todas las salsas!"
	main_btn.show()
	main_btn.text = "🌭 ¡Echar Salsas! (Clic x4)"

func _on_main_btn_pressed() -> void:
	if is_finished: return
	shake_camera(5.0, 0.08)
	
	if current_phase == Phase.OPEN_BREAD:
		bread_clicks -= 1
		main_btn.text = "🥖 Pan (Clic x%d)" % bread_clicks
		if bread_clicks <= 0:
			_setup_phase_2()
			
	elif current_phase == Phase.ADD_SAUCE:
		sauce_clicks -= 1
		main_btn.text = "🌭 ¡Salsas! (Clic x%d)" % sauce_clicks
		if sauce_clicks <= 0:
			phase_label.text = "¡PERRO CALIENTE SUPREMO LISTO!"
			main_btn.disabled = true
			win()

func _on_fly_pressed(fly: Button) -> void:
	if is_finished: return
	fly.hide()
	flies_alive -= 1
	shake_camera(8.0, 0.1)
	if flies_alive <= 0:
		_setup_phase_3()
