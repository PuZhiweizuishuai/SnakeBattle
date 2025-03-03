extends Control

@onready var show_user_view = $VBoxContainer/HBoxContainer
var USER_INFO = preload("res://Scenes/multiplayer_user_info.tscn")
@onready var dialog = $CustomDialog
@onready var dialog_lable = $CustomDialog/ExitDialog/Label

@onready var start_game_btn = $StartGameBtn
@onready var prepare_btn = $PrepareBtn
@onready var ip_lable = $IP
@onready var log = $Log

# 当前用户是否准备好了
var game_ready_to = false
var skin_repeat = false

var _turn := -1

func get_local_ip() -> String:
	var ip_addresses = IP.get_local_addresses()
	var ip : String = ""
	# 检查是否有可用的IP地址
	if ip_addresses.size() > 0:
		for address in ip_addresses:
			# 暂时只显示IPV4地址
			if address.count(".") == 3 && !address.begins_with("127.") && !address.begins_with("fe80:") && !address.begins_with("0:"):
				ip = ip + address + ", "
	else:
		print("未找到本地IP地址。")
	return ip

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 接收皮肤切换信号
	GameManager.skin_change.connect(_on_skin_change)
	# 用户列表更新时触发
	NetworkGameManager.players_updated.connect(on_peer_add)
	# 服务器关闭事件监听
	NetworkGameManager.server_closed.connect(_on_server_closed)
	# 玩家加入退出事件监听
	NetworkGameManager.join_room_success.connect(_on_player_joined)
	NetworkGameManager.player_left.connect(_on_player_left)
	# 初始化日志树
	log.create_item() # 创建根节点
	# 根据是否是服务器来显示对应按钮
	if multiplayer.is_server():
		# 获取本地所有IP地址,只有房主才显示
		ip_lable.text = "房间地址：" + get_local_ip()
		start_game_btn.visible = true
		prepare_btn.visible = false
		# 如果是服务器，记录自己加入房间
		add_log("用户 " + NetworkGameManager.players[0].name + " 创建了房间")
	else:
		ip_lable.visible = false
		start_game_btn.visible = false
		prepare_btn.visible = true
	on_peer_add()

# 添加日志记录
func add_log(message: String) -> void:
	var current_time = Time.get_datetime_dict_from_system()
	var time_str = "%02d:%02d:%02d" % [current_time.hour, current_time.minute, current_time.second]
	var log_message = message + " - " + time_str
	
	var root = log.get_root()
	var item = log.create_item(root)
	item.set_text(0, log_message)
	
	# 自动滚动到最新的日志
	log.scroll_to_item(item)

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
		info_view.change_ready(user.is_ready)

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
	GameManager.play_click()
	GameManager.load_multiplayer_first_ui()
	


func _on_confirm_exit_btn_pressed() -> void:
	GameManager.play_click()
	if skin_repeat == true:
		dialog.visible = false
		return
	dialog.visible = false
	GameManager.load_multiplayer_first_ui()


func _on_cancel_exit_btn_pressed() -> void:
	GameManager.play_click()
	if skin_repeat == true:
		dialog.visible = false
		return
	dialog.visible = false
	GameManager.load_multiplayer_first_ui()


# 开始游戏
func _on_start_game_btn_pressed() -> void:
	if !check_skin():
		skin_repeat = true
		dialog_lable.text = "皮肤不能和已有皮肤重复\n请修改后再开始"
		dialog.visible = true
		return
	skin_repeat = false
	GameManager.play_click()


# 准备游戏
func _on_prepare_btn_pressed() -> void:
	if !game_ready_to:
		# 皮肤旋转判断，不能和已有用户皮肤重复
		if !check_skin():
			skin_repeat = true
			dialog_lable.text = "皮肤不能和已有皮肤重复\n请修改后再准备"
			dialog.visible = true
			return
		prepare_btn.text = "取消准备"
	else:
		prepare_btn.text = "准    备"
	game_ready_to = !game_ready_to
	skin_repeat = false
	GameManager.play_click()
	# 同步准备状态到服务器
	var peer_id = multiplayer.get_unique_id()
	var ready_status = 1 if game_ready_to else 0
	
	# add_log("用户 " + player_name + " 已加入")
	if multiplayer.is_server():
		NetworkGameManager.update_player_ready.call(peer_id, ready_status)
	else:
		NetworkGameManager.update_player_ready.rpc(peer_id, ready_status)
	


func check_skin() -> bool:
	var peer_id = multiplayer.get_unique_id()
	var index = 0
	for player in NetworkGameManager.players:
		if player.id == peer_id:
			index = player.skin_index
	for player in NetworkGameManager.players:
		if player.id == peer_id:
			continue
		if player.skin_index == index:
			return false
	return true

# 处理玩家加入事件
func _on_player_joined(player_name: String) -> void:
	add_log("用户 " + player_name + " 已加入")

# 处理玩家退出事件
func _on_player_left(player_name: String) -> void:
	add_log("用户 " + player_name + " 已退出")
