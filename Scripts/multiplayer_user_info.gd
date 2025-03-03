extends Control

@onready var head = $Head/TextureRect
@onready var nickname = $Nickname
@onready var show_ready = $Label
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	nickname = $Nickname


func change_head(index: int):
	var res = load("res://AssetBundle/Sprites/Snak/sh0" + str(index) + ".png")
	head.texture = res

func change_name(name: String):
	nickname.text = name

func change_ready(is_ready: int):
	if is_ready == 0:
		show_ready.visible = false
	else:
		show_ready.visible = true
	
