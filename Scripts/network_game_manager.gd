extends Node

# 多人游戏控制
# 端口
const PORT = 7000
# 自定义协议名称
const PROTO_NAME = "snake"
# IP
const DEFAULT_SERVER_IP = "127.0.0.1"

# WebSocket多人网络对等体实例
var peer := WebSocketMultiplayerPeer.new()

# 存储用户列表
var players = []

# 服务器创建成功触发
signal create_server_success
# 当玩家列表更新时触发
signal players_updated
# 加入房间成功后触发
signal join_room_success(player_name: String)
# 服务器关闭信号
signal server_closed
# 玩家退出信号
signal player_left(player_name: String)
# 存储用户设定的昵称
var _pending_player_name: String = ""

func _init() -> void:
	# 设置支持的协议列表
	peer.supported_protocols = [PROTO_NAME]  

func create_snake_server(name: String):
	multiplayer.multiplayer_peer = null
	# 创建服务器
	var err = peer.create_server(PORT)
	# 服务器创建失败
	if err != OK:
		print("服务器创建失败！")
		return
					 
	multiplayer.multiplayer_peer = peer      # 设置多人对等体
	# 添加本地玩家
	players.append(UserData.new(1, name))
	# 发送服务器创建成功信号
	create_server_success.emit()
	# 触发玩家列表更新信号
	players_updated.emit()

# 点击"加入房间"按钮
func connect_pressed(host_text: String, nickname: String) -> void:
	multiplayer.multiplayer_peer = null
	# 创建客户端连接（WebSocket地址格式）
	# 保存玩家名称，供后续使用
	_pending_player_name = nickname
	peer.create_client("ws://" + host_text + ":" + str(PORT))
	multiplayer.multiplayer_peer = peer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 连接多玩家信号
	# 新玩家加入
	multiplayer.peer_connected.connect(_peer_connected)
	# 玩家离开
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	
	multiplayer.server_disconnected.connect(_close_network)
	multiplayer.connection_failed.connect(_close_network)
	multiplayer.connected_to_server.connect(_connected)

# 成功连接到服务器时的回调
func _connected() -> void:
	print("成功连接到服务器时的回调")
	# 更新玩家名称
	# 连接成功后，请求设置玩家名称
	var peer_id = multiplayer.get_unique_id()
	request_set_player_name.rpc_id(1, peer_id, _pending_player_name)
	join_room_success.emit(_pending_player_name)

# 新玩家加入连接时回调
func _peer_connected(id: int) -> void:
	if not multiplayer.is_server():
		return
	# 添加新玩家
	var new_player = UserData.new(id, "Player" + str(id))
	players.append(new_player)
	# 同步所有玩家信息给新加入的玩家
	sync_players_info.rpc_id(id, _get_players_data())
	players_updated.emit()
	print("有新玩家加入："  + str(id))

# 对等体断开时的回调
func _peer_disconnected(id: int) -> void:
	# 从玩家列表中移除离开的玩家
	var player_name = ""
	for i in range(players.size() - 1, -1, -1):
		if players[i].id == id:
			player_name = players[i].name
			players.remove_at(i)
			break
	
	if player_name != "":
		if multiplayer.is_server():
			# 服务器广播给所有客户端
			notify_player_left.rpc(player_name)
		player_left.emit(player_name)
	
	# 触发玩家列表更新信号
	players_updated.emit()
	print("玩家离开： " + str(id))

# 关闭网络连接
func _close_network() -> void:
	# 停止游戏
	# 清空玩家列表
	players.clear()
	# 触发玩家列表更新信号
	players_updated.emit()
	multiplayer.multiplayer_peer = null  # 重置多人对等体
	peer.close()  # 关闭网络连接
	# 发送服务器关闭信号
	server_closed.emit()

# 更新玩家信息
@rpc("any_peer")
func update_player_info(id: int, new_name: String, skin_index: int) -> void:
	# 更新本地玩家信息
	for player in players:
		if player.id == id:
			player.name = new_name
			player.skin_index = skin_index
			break
	
	if multiplayer.is_server():
		# 服务器广播给所有客户端
		update_player_info.rpc(id, new_name, skin_index)
	
	# 触发更新信号
	players_updated.emit()

# 更新玩家准备状态
@rpc("any_peer")
func update_player_ready(id: int, is_ready: int) -> void:
	# 更新本地玩家信息
	for player in players:
		if player.id == id:
			player.is_ready = is_ready
			break
	
	if multiplayer.is_server():
		# 服务器广播给所有客户端
		update_player_ready.rpc(id, is_ready)
	
	# 触发更新信号
	players_updated.emit()

# 获取所有玩家数据
func _get_players_data() -> Array:
	var data = []
	for player in players:
		data.append({
			"id": player.id,
			"name": player.name,
			"skin_index": player.skin_index,
			"is_ready": player.is_ready
		})
	return data

# 同步玩家信息
@rpc
func sync_players_info(players_data: Array) -> void:
	players.clear()
	for player_data in players_data:
		var player = UserData.new(
			player_data["id"],
			player_data["name"]
		)
		player.skin_index = player_data["skin_index"]
		player.is_ready = player_data["is_ready"]
		players.append(player)
	players_updated.emit()

# RPC方法来设置玩家名称
@rpc("any_peer")
func request_set_player_name(id: int, new_name: String) -> void:
	if not multiplayer.is_server():
		return
	# 更新玩家名称
	for player in players:
		if player.id == id:
			player.name = new_name
			# 广播给所有客户端有新玩家加入
			notify_new_player.rpc(new_name)
			# 服务器端也触发玩家加入信号
			join_room_success.emit(new_name)
			break
	
	# 广播更新后的玩家列表
	for peer_id in multiplayer.get_peers():
		sync_players_info.rpc_id(peer_id, _get_players_data())
	players_updated.emit()

# 通知所有客户端有新玩家加入
@rpc
func notify_new_player(player_name: String) -> void:
	join_room_success.emit(player_name)

# 通知所有客户端有玩家离开
@rpc
func notify_player_left(player_name: String) -> void:
	player_left.emit(player_name)
