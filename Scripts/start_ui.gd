extends Control

@onready var button_list = $VBoxContainer
@onready var single_game = $VBoxContainer/SingleGame
@onready var exit_dialog = $ExitDialog
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 设置初始状态下单人游戏为焦点
	single_game.grab_focus()
	for button : Button in button_list.get_children():
		button.mouse_entered.connect(button.grab_focus)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# 按下退出游戏事件
func _on_exit_btn_pressed() -> void:
	if exit_dialog.visible != true:
		exit_dialog.visible = true
		$AnimationPlayer.play("show_exit_dialog_animation")


# 确认退出事件
func _on_confirm_exit_btn_pressed() -> void:
	get_tree().quit()



# 取消退出事件
func _on_cancel_exit_btn_pressed() -> void:
	exit_dialog.visible = false


# 进入关于页面
func _on_about_pressed() -> void:
	# 只有关于、设置界面需要条判断，因为别的按钮会被退出按钮遮挡
	if exit_dialog.visible != true:
		pass # Replace with function body.

# 进入设置页面
func _on_setting_pressed() -> void:
	if exit_dialog.visible != true:
		pass # Replace with function body.
	
# 

# 进入多人游戏界面
func _on_multiplayer_pressed() -> void:
	GameManager.load_multiplayer_first_ui()


# 进入单人游戏界面
func _on_single_game_pressed() -> void:
	GameManager.load_single_player_borderless_mode()
