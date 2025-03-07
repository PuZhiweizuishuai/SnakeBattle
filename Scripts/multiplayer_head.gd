extends Area2D

# 启用 GPU 加速
@export var use_gpu_instancing = true

@onready var head = $Sprite2D
@onready var BODY_SEGMENT = preload("res://Scenes/body_segment.tscn")  # 多人游戏身体预制件

const BASE_SEGMENT_GAP = 30       # 固定的基础间距
var current_speed = 200.0         # 当前实际速度
var trail_sample_distance = 0.0   # 轨迹采样距离累计器

var body_segments = []            # 存储身体段的数组
var trail_positions = []          # 记录头部移动轨迹
var direction = Vector2.RIGHT     # 初始移动方向

@export var interpolation_weight = 0.3  # 插值权重
@export var initial_length = 4          # 蛇的初始长度

var viewport_size = null
var is_local_player = false       # 是否为本地玩家
var player_id = 0                 # 玩家ID
var skin_index = 0                # 皮肤索引
var body_z_index = 9999
# 多人游戏同步变量
@export var sync_position = Vector2.ZERO
@export var sync_direction = Vector2.RIGHT

func _ready():
	viewport_size = get_viewport_rect().size
	player_id = int(name)
	is_local_player = player_id == multiplayer.get_unique_id()
	# 设置多人游戏权限
	set_multiplayer_authority(player_id)
	
	# 初始化蛇
	start_game()

# 初始化蛇的皮肤
func init_snake_skin(skin_idx):
	skin_index = skin_idx
	head.texture = load("res://AssetBundle/Sprites/Snak/sh0"+ str(skin_idx) +".png")

func start_game():
	body_segments.clear()
	trail_positions = [global_position]  # 初始化轨迹记录
	
	# 添加初始的轨迹点和身体段
	for i in range(initial_length + 2):
		grow()

# 只有本地玩家才能控制自己的蛇
func _physics_process(delta: float) -> void:
	if is_local_player:
		# 本地玩家控制
		handle_local_input(delta)
		# 同步位置和方向到其他玩家
		sync_movement.rpc(global_position, direction)
	
	# 更新身体
	update_trail(delta)
	update_body()

# 处理本地输入
func handle_local_input(delta):
	# 方向输入处理
	var dir = Input.get_vector("left","right","up", "down")
	if dir != Vector2.ZERO:
		direction = dir.normalized()
	
	# 更新当前速度
	if Input.is_action_pressed("speed_up"):
		current_speed = 400.0  # 加速时速度翻倍
	else:
		current_speed = 200.0
	
	# 移动头部
	position += direction * current_speed * delta
	rotation = direction.angle() + TAU / 4
	
	# 处理屏幕边界穿越
	handle_screen_wrap()

# 处理屏幕边界穿越
func handle_screen_wrap():
	if position.x < 0:
		position.x = viewport_size.x
	elif position.x > viewport_size.x:
		position.x = 0
	if position.y < 0:
		position.y = viewport_size.y
	elif position.y > viewport_size.y:
		position.y = 0

# 更新轨迹
func update_trail(delta):
	trail_positions[0] = global_position
	
	# 优化轨迹采样
	trail_sample_distance += (direction * current_speed * delta).length()
	if trail_sample_distance >= BASE_SEGMENT_GAP * 0.5:
		trail_positions.insert(1, trail_positions[0])
		trail_sample_distance = 0.0
		
		if trail_positions.size() > (body_segments.size() + 1) * 2:
			trail_positions.pop_back()

# 更新身体段位置
func update_body():
	var target_positions = trail_positions
	
	while body_segments.size() < (target_positions.size() - 1) / 2:
		var new_segment : Area2D = BODY_SEGMENT.instantiate()
		
		get_parent().add_child(new_segment)
		# 设置身体段的所有者ID
		new_segment.set_meta("owner_id", player_id)
		# 设置身体段的皮肤
		new_segment.z_index = body_z_index - 1 
		body_z_index = body_z_index - 1
		new_segment.set_skin(skin_index)
		var segment_index = body_segments.size()
		var target_idx = (segment_index + 1) * 2
		if target_idx < target_positions.size():
			new_segment.global_position = target_positions[target_idx]
		body_segments.append(new_segment)
	
	for i in range(body_segments.size()):
		var target_idx = (i + 1) * 2
		if target_idx < target_positions.size():
			var target_pos = target_positions[target_idx]
			var current_pos = body_segments[i].global_position
			
			# 检查是否发生穿越
			var distance = abs(current_pos.x - target_pos.x)
			var distance_y = abs(current_pos.y - target_pos.y)
			
			if distance > viewport_size.x / 2 or distance_y > viewport_size.y / 2:
				body_segments[i].global_position = target_pos
			else:
				body_segments[i].global_position = body_segments[i].global_position.lerp(
					target_pos, 
					interpolation_weight
				)

# 增长蛇身
func grow():
	var last_position = trail_positions.back()
	trail_positions.push_back(last_position)

# 同步移动数据到其他玩家
@rpc("unreliable")
func sync_movement(pos, dir):
	if not is_local_player:
		global_position = pos
		direction = dir
		rotation = direction.angle() + TAU / 4

# 碰撞检测
func _on_area_entered(area):
	# 只有本地玩家才处理碰撞
	if not is_local_player:
		return
		
	# 碰撞检测（当碰到食物时）
	if area.is_in_group("food"):
		# 通知服务器食物被吃
		NetworkGameManager.notify_food_eaten.rpc_id(1, area.get_path())
		# 通知服务器蛇增长了（服务器会广播给所有客户端）
		NetworkGameManager.snake_grow.rpc_id(1, player_id)
		# 蛇的长度增加
		grow()
	elif area.is_in_group("body"):
		# 需要判断这个身体段是否属于自己
		# 获取身体段的所有者ID
		var segment_owner_id = area.get_meta("owner_id") if area.has_meta("owner_id") else -1
		# 如果身体段不属于自己，则判定为死亡
		if segment_owner_id != player_id:
			print("你死了! 碰到了玩家", segment_owner_id, "的身体")
			player_died.rpc()

# 通知服务器食物被吃
@rpc("reliable", "any_peer", "call_local")
func food_eaten(food_path):
	if multiplayer.is_server():
		# 服务器处理食物被吃的逻辑
		var food = get_node_or_null(food_path)
		if food:
			food.queue_free()
			# 生成新的食物
			NetworkGameManager.eat_food.emit()

# 玩家死亡
@rpc("reliable", "any_peer", "call_local")
func player_died():
	if is_local_player:
		# 本地玩家死亡逻辑
		print("你死了!")
