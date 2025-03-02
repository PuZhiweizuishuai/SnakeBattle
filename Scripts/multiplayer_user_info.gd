extends Control

@onready var head = $Head/TextureRect
@onready var nickname = $Nickname
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	nickname = $Nickname


func change_head(index: int):
	var res = load("res://AssetBundle/Sprites/Snak/sh0" + str(index) + ".png")
	head.texture = res

func change_name(name: String):
	nickname.text = name
	
