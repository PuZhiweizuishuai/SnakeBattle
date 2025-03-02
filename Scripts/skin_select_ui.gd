extends Control


# 将皮肤和模式对应的Sprite组织成数组
@onready var skin_sprites = [
	$SkinContainer/HBoxContainer/BlueSnakeButton/Sprite2D,
	$SkinContainer/HBoxContainer/YellowSnakeButton/Sprite2D,
	$SkinContainer/HBoxContainer/GirlSnakeButton/Sprite2D,
	$SkinContainer/HBoxContainer/ChouxiangSnakeButton2/Sprite2D
]

# 通用皮肤选择函数
func select_skin(index: int) -> void:
	for i in skin_sprites.size():
		skin_sprites[i].visible = (i == index)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_blue_snake_button_pressed() -> void:
	# 发生皮肤切换信号
	GameManager.skin_change.emit(0)
	select_skin(0)


func _on_yellow_snake_button_pressed() -> void:
	GameManager.skin_change.emit(1)
	select_skin(1)


func _on_girl_snake_button_pressed() -> void:
	GameManager.skin_change.emit(2)
	select_skin(2)


func _on_chouxiang_snake_button_2_pressed() -> void:
	GameManager.skin_change.emit(3)
	select_skin(3)
