extends Control


# 将皮肤和模式对应的Sprite组织成数组
@onready var skin_sprites = [
	$SkinContainer/HBoxContainer/BlueSnakeButton/Sprite2D,
	$SkinContainer/HBoxContainer/YellowSnakeButton/Sprite2D,
	$SkinContainer/HBoxContainer/GirlSnakeButton/Sprite2D,
	$SkinContainer/HBoxContainer/ChouxiangSnakeButton2/Sprite2D
]

@onready var mode_sprites = [
	$ModeContainer/HBoxContainer/BoundaryMode/Sprite2D,
	$ModeContainer/HBoxContainer/FreeMode/Sprite2D
]

# 通用皮肤选择函数
func select_skin(index: int) -> void:
	for i in skin_sprites.size():
		skin_sprites[i].visible = (i == index)
	GameManager.SingleGameSkin = index

# 通用模式选择函数
func select_mode(index: int) -> void:
	for i in mode_sprites.size():
		mode_sprites[i].visible = (i == index)
	GameManager.SingleGameMode = index

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 初始化时选择第一个皮肤和模式
	select_skin(0)
	select_mode(0)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# 返回
func _on_back_btn_pressed() -> void:
	GameManager.load_start_ui()

# 开始游戏
func _on_start_btn_pressed() -> void:
	GameManager.restart_game()

# 切换自由模式
func _on_free_mode_pressed() -> void:
	select_mode(1)

# 切换边界模式
func _on_boundary_mode_pressed() -> void:
	select_mode(0)


# 皮肤按钮处理（示例：蓝色按钮）
func _on_blue_snake_button_pressed() -> void:
	select_skin(0)

func _on_yellow_snake_button_pressed() -> void:
	select_skin(1)


# 切换女孩
func _on_girs_snake_button_pressed() -> void:
	select_skin(2)

# 抽象皮肤
func _on_chouxiang_snake_button_2_pressed() -> void:
	select_skin(3)
