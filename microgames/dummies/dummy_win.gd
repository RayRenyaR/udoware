#MINIJUEGO
#DUMMY WIN
#LIT SOLO GANAS CUANDO PRESIONAS EL BOTON 
#y ya.
extends MicrogameBase

func _ready():
	# Llamamos al _ready() de la clase padre por si acaso
	super._ready()
	# Conectamos el boton
	$GameplayArea/Button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	win() # Ganaste!
