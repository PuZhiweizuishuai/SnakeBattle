extends Node

# 多人游戏控制
# 端口
const PORT = 7000
# 自定义协议名称
const PROTO_NAME = "snake"
# IP
const DEFAULT_SERVER_IP = "127.0.0.1"

# WebSocket多人网络对等体实例 WebSocketMultiplayerPeer WebRTCMultiplayerPeer
var peer := WebSocketMultiplayerPeer.new()

# 存储用户列表
var players: Array = []
# 蛇的数据，键值对 key 为 peer_id， value 为 SnakeInfoData
var snakeInfoMap = {}

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
# 游戏开始信号
signal start_game
# 吃到食物
signal eat_food

# 存储用户设定的昵称
var _pending_player_name: String = ""

func _init() -> void:
	# 设置支持的协议列表
	peer.supported_protocols = [PROTO_NAME]
	# 优化 WebSocket 设置
#	peer.handshake_headers = ["Sec-WebSocket-Protocol: " + PROTO_NAME]
	#peer.inbound_buffer_size = 65536  # 增加缓冲区大小
	#peer.outbound_buffer_size = 65536

func _ready() -> void:
	_connect_multiplayer_signals()

# 信号连接
func _connect_multiplayer_signals() -> void:
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.server_disconnected.connect(_close_network)
	multiplayer.connection_failed.connect(_close_network)
	multiplayer.connected_to_server.connect(_connected)

# 服务器管理
func create_snake_server(username: String) -> void:
	_reset_network_state()
	
	if peer.create_server(PORT) != OK:
		print("服务器创建失败！")
		return
	multiplayer.multiplayer_peer = peer      # 设置多人对等体
	# 添加本地玩家
	players.append(UserData.new(1, username))
	# 发送服务器创建成功信号
	create_server_success.emit()
	# 触发玩家列表更新信号
	players_updated.emit()

# 点击"加入房间"按钮
func connect_pressed(host_text: String, nickname: String) -> void:
	_reset_network_state()
	# 创建客户端连接（WebSocket地址格式）
	# 保存玩家名称，供后续使用
	_pending_player_name = nickname
	peer.create_client("ws://" + host_text + ":" + str(PORT))
	multiplayer.multiplayer_peer = peer

# 网络状态重置
func _reset_network_state() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()

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
	var player_name = _remove_player(id)
	if player_name.is_empty():
		return
	
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
	_update_player_property(id, "name", new_name)
	_update_player_property(id, "skin_index", skin_index)
	
	if multiplayer.is_server():
		# 服务器广播给所有客户端
		update_player_info.rpc(id, new_name, skin_index)
	
	# 触发更新信号
	players_updated.emit()

# 更新玩家准备状态
@rpc("any_peer")
func update_player_ready(id: int, is_ready: int) -> void:
	_update_player_property(id, "is_ready", is_ready)
	
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

func get_user_name(id: int) -> String:
	for player in players:
		if player.id == id:
			return player.name
	return ""

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
	_update_player_property(id, "name", new_name)
	notify_new_player.rpc(new_name)
	
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

# 辅助函数
func _update_player_property(id: int, property: String, value) -> void:
	for player in players:
		if player.id == id:
			player.set(property, value)
			break

func _remove_player(id: int) -> String:
	for i in range(players.size() - 1, -1, -1):
		if players[i].id == id:
			var name = players[i].name
			players.remove_at(i)
			return name
	return ""

# 开始游戏
@rpc
func start_multiplayer_game() -> void:
	# 发送开始游戏信号
	start_game.emit()
	
# 服务器端生成蛇头部位置，之后同步到各个客户端
func snake_head_initial_position():
	if not multiplayer.is_server():
		return
	var positions_data = {}	
	for player in players:
		var snakeInfo = SnakeInfoData.new()
		# 随机初始位置
		snakeInfo.random_position()
		# 随机初始方向
		var directions = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
		snakeInfo.direction = directions[randi() % directions.size()]
		
		# 只传输位置数据和方向
		positions_data[str(player.id)] = {
			"position": snakeInfo.init_position,
			"direction": snakeInfo.direction
		}
		snakeInfoMap[str(player.id)] = snakeInfo
	
	# 同步位置到所有客户端
	sync_initial_positions.rpc(positions_data)

# 同步初始位置
@rpc("reliable")
func sync_initial_positions(positions: Dictionary):
	snakeInfoMap.clear()
	# 接收到位置数据后，创建新的SnakeInfoData对象
	for player_id in positions:
		var snakeInfo = SnakeInfoData.new()
		snakeInfo.init_position = positions[player_id]["position"]
		snakeInfo.direction = positions[player_id]["direction"]
		snakeInfoMap[player_id] = snakeInfo

# 服务器生成食物并同步到客户端
@rpc("reliable", "call_local")
func spawn_network_food(food_position: Vector2):
	# 这个函数会在服务器和所有客户端上执行
	eat_food.emit(food_position)

# 通知服务器食物被吃掉
@rpc("reliable", "any_peer", "call_local")
func notify_food_eaten(food_position: Vector2):
	if not multiplayer.is_server():
		return
		
	# 获取吃食物的玩家ID
	var player_id = multiplayer.get_remote_sender_id()
	if player_id == 0:  # 如果是服务器自己吃的
		player_id = 1
	var player_name = get_user_name(player_id)
	print("玩家 ", player_name, " 吃到了食物")
	
	# 通知所有客户端删除这个食物
	remove_food.rpc(food_position)
	
	# 通知所有客户端让对应玩家的蛇增长
	snake_grow.rpc(player_id)
	
	# 延迟生成新食物
	call_deferred("_spawn_new_food")

# 延迟生成新食物
func _spawn_new_food():
	# 生成新食物
	var new_food_pos = Vector2(
		randf_range(50, GameManager.SHOW_RANGE.x - 50),
		randf_range(50, GameManager.SHOW_RANGE.y - 50)
	)
	
	# 同步新食物到所有客户端
	spawn_network_food.rpc(new_food_pos)

# 新增：通知所有客户端删除食物
@rpc("reliable", "call_local")
func remove_food(food_position: Vector2):
	# 找到对应位置的食物并删除
	var foods = get_tree().get_root().find_child("Foods", true, false)
	if foods:
		for food in foods.get_children():
			if food.position.distance_to(food_position) < 1.0:  # 使用一个小的阈值来判断是否是同一个位置
				food.queue_free()
				break

# 通知所有客户端某个玩家的蛇增长了
@rpc("reliable", "call_local")
func snake_grow(player_id: int):
	# 找到对应的蛇头并调用grow方法
	var snake_head = get_tree().get_root().find_child(str(player_id), true, false)
	if snake_head:
		snake_head.call_deferred("grow_from_server")

# 客户端通知服务器玩家死亡
@rpc("reliable", "any_peer")
func notify_player_death(death_pos: Vector2, count: int):
	if not multiplayer.is_server():
		return
	# 服务器收到通知后调用生成食物的函数
	spawn_death_foods(death_pos, count)

# 在死亡位置生成食物（服务器端函数）
func spawn_death_foods(death_pos: Vector2, count: int):
	if not multiplayer.is_server():
		return
		
	# 创建一个计时器来延迟生成食物
	var timer = get_tree().create_timer(0.5).timeout
	await timer
	
	# 在死亡位置周围随机生成食物
	for i in range(count):
		var offset = Vector2(
			randf_range(-50, 50),
			randf_range(-50, 50)
		)
		var food_pos = death_pos + offset
		
		# 确保食物在游戏区域内
		food_pos.x = clamp(food_pos.x, 50, GameManager.SHOW_RANGE.x - 50)
		food_pos.y = clamp(food_pos.y, 50, GameManager.SHOW_RANGE.y - 50)
		
		# 每隔一小段时间生成一个食物
		if i > 0:
			await get_tree().create_timer(0.1).timeout
		
		# 同步食物到所有客户端
		spawn_network_food.rpc(food_pos)
