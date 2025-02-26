extends Area2D


func _ready():
	 # 初始化随机数种子
	randomize()
	# 随机旋转图片为食物
	var sprite2d = $Sprite2D
	var random_int_in_range = randi() % 10 + 1
	var new_texture
	if random_int_in_range < 10:
		new_texture = load("res://AssetBundle/Sprites/Food/icecream-0" + str(random_int_in_range)+".png")
	else:
		new_texture = preload("res://AssetBundle/Sprites/Food/icecream-10.png")
	sprite2d.texture = new_texture
	add_to_group("food")
