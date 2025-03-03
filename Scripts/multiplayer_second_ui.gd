extends Control

# 节点引用
@onready var show_user_view = $VBoxContainer/HBoxContainer
@onready var dialog = $CustomDialog
@onready var dialog_lable = $CustomDialog/ExitDialog/Label
@onready var start_game_btn = $StartGameBtn
@onready var prepare_btn = $PrepareBtn
@onready var ip_lable = $IP
@onready var log = $Log

# 常量
const USER_INFO = preload("res://Scenes/multiplayer_user_info.tscn")

# 状态变量
var game_ready_to := false
var skin_repeat := false

# 初始化函数
func _ready() -> void:
	_init_signals()
	_init_log()
	_init_ui()

# 信号初始化
func _init_signals() -> void:
	GameManager.skin_change.connect(_on_skin_change)
	NetworkGameManager.players_updated.connect(_on_peer_add)
	NetworkGameManager.server_closed.connect(_on_server_closed)
	NetworkGameManager.join_room_success.connect(_on_player_joined)
	NetworkGameManager.player_left.connect(_on_player_left)

# 日志初始化
func _init_log() -> void:
	log.create_item()
	if multiplayer.is_server():
		add_log("用户 " + NetworkGameManager.players[0].name + " 创建了房间")

# UI初始化
func _init_ui() -> void:
	if multiplayer.is_server():
		ip_lable.text = "房间地址：" + _get_local_ip()
		start_game_btn.visible = true
		prepare_btn.visible = false
	else:
		ip_lable.visible = false
		start_game_btn.visible = false
		prepare_btn.visible = true
	_on_peer_add()

# 获取本地IP地址
func _get_local_ip() -> String:
	var ip := ""
	for address in IP.get_local_addresses():
		if _is_valid_ipv4(address):
			ip += address + ", "
	return ip

# 验证IPv4地址
func _is_valid_ipv4(address: String) -> bool:
	return address.count(".") == 3 && !address.begins_with("127.") && !address.begins_with("fe80:") && !address.begins_with("0:")

# 添加日志记录
func add_log(message: String) -> void:
	var time_str = _get_current_time()
	var log_message = message + " - " + time_str
	var root = log.get_root()
	var item = log.create_item(root)
	item.set_text(0, log_message)
	log.scroll_to_item(item)

# 获取当前时间字符串
func _get_current_time() -> String:
	var time = Time.get_datetime_dict_from_system()
	return "%02d:%02d:%02d" % [time.hour, time.minute, time.second]

# 更新用户视图
func _on_peer_add() -> void:
	_clear_user_views()
	for user in NetworkGameManager.players:
		var info_view = USER_INFO.instantiate()
		show_user_view.add_child(info_view)
		info_view.change_name(user.name)
		info_view.change_head(user.skin_index)
		info_view.change_ready(user.is_ready)

# 清除用户视图
func _clear_user_views() -> void:
	for child in show_user_view.get_children():
		child.queue_free()

# 皮肤变更处理
func _on_skin_change(index: int) -> void:
	if game_ready_to && !multiplayer.is_server():
		return
		
	var peer_id = multiplayer.get_unique_id()
	var player_name = _get_player_name(peer_id)
	
	if multiplayer.is_server():
		NetworkGameManager.update_player_info.call(peer_id, player_name, index)
	else:
		NetworkGameManager.update_player_info.rpc(peer_id, player_name, index)

# 获取玩家名称
func _get_player_name(peer_id: int) -> String:
	for player in NetworkGameManager.players:
		if player.id == peer_id:
			return player.name
	return ""

# 检查皮肤是否重复
func check_skin() -> bool:
	var peer_id = multiplayer.get_unique_id()
	var current_skin_index = _get_player_skin_index(peer_id)
	
	for player in NetworkGameManager.players:
		if player.id != peer_id && player.skin_index == current_skin_index:
			return false
	return true

# 获取玩家皮肤索引
func _get_player_skin_index(peer_id: int) -> int:
	for player in NetworkGameManager.players:
		if player.id == peer_id:
			return player.skin_index
	return 0

# 事件处理函数
func _on_server_closed() -> void:
	dialog_lable.text = "房主已解散本房间！"
	dialog.visible = true

func _on_back_btn_pressed() -> void:
	_handle_exit()
	GameManager.play_click()
	GameManager.load_multiplayer_first_ui()

func _handle_exit() -> void:
	if multiplayer.is_server():
		NetworkGameManager._close_network()
	elif multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()

func _on_confirm_exit_btn_pressed() -> void:
	GameManager.play_click()
	dialog.visible = false
	if !skin_repeat:
		GameManager.load_multiplayer_first_ui()

func _on_cancel_exit_btn_pressed() -> void:
	GameManager.play_click()
	dialog.visible = false
	if !skin_repeat:
		GameManager.load_multiplayer_first_ui()

func _on_start_game_btn_pressed() -> void:
	if !check_skin():
		_show_skin_repeat_dialog()
		return
	skin_repeat = false
	GameManager.play_click()

func _on_prepare_btn_pressed() -> void:
	if !game_ready_to && !check_skin():
		_show_skin_repeat_dialog()
		return
		
	_toggle_prepare_status()
	_update_prepare_button()
	_sync_ready_status()
	
	skin_repeat = false
	GameManager.play_click()

func _show_skin_repeat_dialog() -> void:
	skin_repeat = true
	dialog_lable.text = "皮肤不能和已有皮肤重复\n请修改后再" + ("开始" if multiplayer.is_server() else "准备")
	dialog.visible = true

func _toggle_prepare_status() -> void:
	game_ready_to = !game_ready_to

func _update_prepare_button() -> void:
	prepare_btn.text = "取消准备" if game_ready_to else "准    备"

func _sync_ready_status() -> void:
	var peer_id = multiplayer.get_unique_id()
	var ready_status = 1 if game_ready_to else 0
	
	if multiplayer.is_server():
		NetworkGameManager.update_player_ready.call(peer_id, ready_status)
	else:
		NetworkGameManager.update_player_ready.rpc(peer_id, ready_status)

# 玩家加入/退出事件处理
func _on_player_joined(player_name: String) -> void:
	add_log("用户 " + player_name + " 已加入")

func _on_player_left(player_name: String) -> void:
	add_log("用户 " + player_name + " 已退出")
