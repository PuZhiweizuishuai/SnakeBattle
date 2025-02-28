extends Control

@onready var blue_snake = $SkinContainer/HBoxContainer/BlueSnakeButton/Sprite2D
@onready var yelow_snake = $SkinContainer/HBoxContainer/YellowSnakeButton/Sprite2D

@onready var bm = $ModeContainer/HBoxContainer/BoundaryMode/Sprite2D
@onready var fm = $ModeContainer/HBoxContainer/FreeMode/Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	blue_snake.visible = true
	bm.visible = true
	yelow_snake.visible = false
	fm.visible = false
	GameManager.SingleGameMode = 0
	GameManager.SingleGameSkin = 0
	
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
	fm.visible = true
	bm.visible = false
	GameManager.SingleGameMode = 1

# 切换边界模式
func _on_boundary_mode_pressed() -> void:
	GameManager.SingleGameMode = 0
	bm.visible = true
	fm.visible = false

# 切换黄色小蛇
func _on_yellow_snake_button_pressed() -> void:
	GameManager.SingleGameSkin = 1
	yelow_snake.visible = true
	blue_snake.visible = false

# 切换蓝色小蛇
func _on_blue_snake_button_pressed() -> void:
	GameManager.SingleGameSkin = 0
	yelow_snake.visible = false
	blue_snake.visible = true
