extends Node2D

@onready var joystick = $UI/VirtualJoystick
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.get_name() == "Windows" || !GameManager.open_joystick:
		joystick.visible = false
		remove_child(joystick)
		joystick.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_btn_pressed() -> void:
	GameManager.load_single_player_borderless_mode()
