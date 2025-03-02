extends Control

@onready var show_user_view = $VBoxContainer/HBoxContainer
var USER_INFO = preload("res://Scenes/multiplayer_user_info.tscn")
@onready var dialog = $CustomDialog
@onready var dialog_lable = $CustomDialog/ExitDialog/Label

@onready var start_game_btn = $StartGameBtn
@onready var prepare_btn = $PrepareBtn

# 当前用户是否准备好了
var game_ready_to = false

var _turn := -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 接收皮肤切换信号
	GameManager.skin_change.connect(_on_skin_change)
	# 用户列表更新时触发
	NetworkGameManager.players_updated.connect(on_peer_add)
	# 服务器关闭事件监听
	NetworkGameManager.server_closed.connect(_on_server_closed)
	# 根据是否是服务器来显示对应按钮
	if multiplayer.is_server():
		start_game_btn.visible = true
		prepare_btn.visible = false
	else:
		start_game_btn.visible = false
		prepare_btn.visible = true
	on_peer_add()


# 清除所有用户视图
func _clear_user_views() -> void:
	for child in show_user_view.get_children():
		child.queue_free()
		
# 当有新玩家加入时处理
func on_peer_add() -> void:
	_clear_user_views()
	# 显示所有玩家信息
	for user in NetworkGameManager.players:
		var info_view = USER_INFO.instantiate()
		show_user_view.add_child(info_view)
		info_view.change_name(user.name)
		info_view.change_head(user.skin_index)

func _on_skin_change(index: int):
	# 当本地玩家更改皮肤时，通知服务器更新信息
	var peer_id = multiplayer.get_unique_id()
	var player_name = ""
	for player in NetworkGameManager.players:
		if player.id == peer_id:
			player_name = player.name
			break
	# 如果是服务器，直接调用方法
	if multiplayer.is_server():
		NetworkGameManager.update_player_info.call(peer_id, player_name, index)
	else:
		# 如果是客户端，使用RPC
		# 如果已经准备，则禁止切换皮肤
		if game_ready_to:
			return
		NetworkGameManager.update_player_info.rpc(peer_id, player_name, index)
	 

func _on_server_closed():
	dialog_lable.text = "房主已解散本房间！"
	dialog.visible = true

# 返回上一页
func _on_back_btn_pressed() -> void:
	# 如果是服务器，则关闭服务器
	if multiplayer.is_server():
		NetworkGameManager._close_network()
	else:
		# 如果是客户端，则断开连接
		if multiplayer.multiplayer_peer:
			multiplayer.multiplayer_peer.close()
	GameManager.load_multiplayer_first_ui()
	


func _on_confirm_exit_btn_pressed() -> void:
	dialog.visible = false
	GameManager.load_multiplayer_first_ui()


func _on_cancel_exit_btn_pressed() -> void:
	dialog.visible = false
	GameManager.load_multiplayer_first_ui()


# 开始游戏
func _on_start_game_btn_pressed() -> void:
	pass # Replace with function body.


# 准备游戏
func _on_prepare_btn_pressed() -> void:
	if !game_ready_to:
		prepare_btn.text = "取消准备"
	else:
		prepare_btn.text = "准    备"
	game_ready_to = !game_ready_to
