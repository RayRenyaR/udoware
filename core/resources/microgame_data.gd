#MicrogameData
#Todos los minijuegos tienen sus "metadatos"
extends Resource
class_name MicrogameData

@export var id: String = ""
@export var title: String = ""
@export var command_text: String = "¡JUEGA!"
@export var story_id: String = "historia_1" 
@export var is_boss: bool = false
@export var base_duration: float = 4.0
@export var scene: PackedScene
