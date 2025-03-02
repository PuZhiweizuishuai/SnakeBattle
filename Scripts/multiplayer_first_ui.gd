extends Control

@onready var server_host = $VBoxContainer/ServerAddress
@onready var nickname = $VBoxContainer/Nickname
@onready var dialog_lable = $CustomDialog/ExitDialog/Label
@onready var dialog = $CustomDialog
func _ready() -> void:
	NetworkGameManager.join_room_success.connect(GameManager.load_multiplayer_second_ui)
	NetworkGameManager.create_server_success.connect(GameManager.load_multiplayer_second_ui)

# 返回上一页
func _on_back_btn_pressed() -> void:
	GameManager.load_start_ui()

# 创建房间
func _on_create_room_btn_pressed() -> void:
	# 创建服务器
	# 检查昵称是否为空
	if nickname.text.is_empty():
		dialog_lable.text = "昵称不能为空！"
		dialog.visible = true
		return
	if nickname.text.length() > 7:
		dialog_lable.text = "为了显示效果，昵称最大不得\n超过七个字符！"
		dialog.visible = true
		return		
	NetworkGameManager.create_snake_server(nickname.text)


# 加入房间
func _on_join_room_btn_pressed() -> void:
	# 检查昵称是否为空
	if nickname.text.is_empty():
		dialog_lable.text = "昵称不能为空！"
		dialog.visible = true
		return
	if nickname.text.length() > 7:
		dialog_lable.text = "为了显示效果，昵称最大不得\n超过七个字符！"
		dialog.visible = true
		return		
	if server_host.text.is_empty():
		dialog_lable.text = "房间地址不能为空"
		dialog.visible = true
		return
	NetworkGameManager.connect_pressed(server_host.text, nickname.text)


# 消息弹框 确认
func _on_confirm_exit_btn_pressed() -> void:
	dialog.visible = false


func _on_cancel_exit_btn_pressed() -> void:
	dialog.visible = false
	
func _exit_tree() -> void:
	if NetworkGameManager.join_room_success.is_connected(GameManager.load_multiplayer_second_ui):
		NetworkGameManager.join_room_success.disconnect(GameManager.load_multiplayer_second_ui)
	if NetworkGameManager.create_server_success.is_connected(GameManager.load_multiplayer_second_ui):
		NetworkGameManager.create_server_success.disconnect(GameManager.load_multiplayer_second_ui)	
