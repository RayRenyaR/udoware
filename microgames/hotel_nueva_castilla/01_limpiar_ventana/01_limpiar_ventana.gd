extends MicrogameBase

@onready var window_frame: ColorRect = $GameplayArea/WindowFrame
@onready var progress_label: Label = $GameplayArea/ProgressLabel

var dirt_patches: Array[ColorRect] = []
var total_patches: int = 0
var cleaned_patches: int = 0
const CLEAN_RADIUS: float = 55.0
const TARGET_PERCENT: float = 0.80

func _ready() -> void:
	super._ready()
	_spawn_dirt_grid()
	_update_label()

func _spawn_dirt_grid() -> void:
	var cols: int = 12
	var rows: int = 8
	var cell_size: Vector2 = window_frame.size / Vector2(cols, rows)
	
	for r in range(rows):
		for c in range(cols):
			var patch := ColorRect.new()
			patch.color = Color(0.45, 0.32, 0.2, 0.9) # Color suciedad
			patch.size = cell_size + Vector2(1, 1)
			patch.position = window_frame.position + Vector2(c * cell_size.x, r * cell_size.y)
			$GameplayArea.add_child(patch)
			dirt_patches.append(patch)
			
	total_patches = dirt_patches.size()

func _input(event: InputEvent) -> void:
	if is_finished: return
	if event is InputEventMouseMotion:
		var mouse_pos: Vector2 = get_global_mouse_position()
		for patch in dirt_patches:
			if patch.visible:
				var patch_center: Vector2 = patch.global_position + (patch.size * 0.5)
				if mouse_pos.distance_to(patch_center) <= CLEAN_RADIUS:
					patch.hide()
					cleaned_patches += 1
					
		_update_label()
		if float(cleaned_patches) / float(total_patches) >= TARGET_PERCENT:
			win()

func _update_label() -> void:
	var pct: int = int((float(cleaned_patches) / float(total_patches)) * 100.0)
	progress_label.text = "Limpieza: %d%% / 80%%" % pct
