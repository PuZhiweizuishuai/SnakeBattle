extends Area2D
# 启用 GPU 加速
@export var use_gpu_instancing = true

@export var SPEED = 200.0            # 基础移动速度
var BODY_SEGMENT = preload("res://Scenes/body_segment.tscn")  # 身体预制件
# 头部
@onready var head = $Sprite2D

const BASE_SEGMENT_GAP = 30       # 固定的基础间距
var current_speed = SPEED          # 当前实际速度
var trail_sample_distance = 0.0    # 轨迹采样距离累计器

var body_segments = []         # 存储身体段的数组

var trail_positions = []       # 记录头部移动轨迹

var direction = Vector2.RIGHT  # 初始移动方向

@export var interpolation_weight = 0.3  # 插值权重，可以根据需要调整

@export var initial_length = 4 # 蛇的初始长度

var viewport_size = null

func _ready():
	# TODO 随机初始位置与方向
	viewport_size = get_viewport_rect().size
	direction = Vector2.RIGHT
	start_game()

func start_game():
	# 初始化皮肤
	# 蓝皮


	head.texture = load("res://AssetBundle/Sprites/Snak/sh0"+ str(GameManager.SingleGameSkin) +".png")
	body_segments.clear()
	trail_positions = [global_position]  # 初始化轨迹记录
	# 新增：添加初始的轨迹点和身体段
	for i in range(initial_length + 2):
		grow()



func _physics_process(delta: float) -> void:
	# 方向输入处理（使用键盘方向键）
	var dir = Input.get_vector("left","right","up", "down")
	if dir != Vector2.ZERO:
		# 使用 direction.lerp(dir, rotation_smoothing)可以让旋转更平滑，不过目前不需要
		# direction = direction.lerp(dir, rotation_smoothing)  # 平滑方向变化
		# 归一化向量，保持速度一直
		direction = dir.normalized()
	
	# 更新当前速度
	if Input.is_action_pressed("speed_up"):
		current_speed = SPEED * 2  # 加速时速度翻倍
	else:
		current_speed = SPEED
	
	# 移动头部
	position += direction * current_speed * delta
	rotation = direction.angle() + TAU / 4
	
	# 模式管理
	if GameManager.SingleGameMode == 0:
		# 处理屏幕边界穿越
		if position.x < 0 or position.x > viewport_size.x or position.y < 0 or position.y > viewport_size.y:
			# 游戏结束
			GameManager.play_die()
			GameManager.lose_game()
	else:
		# 处理屏幕边界穿越
		if position.x < 0:
			position.x = viewport_size.x
		elif position.x > viewport_size.x:
			position.x = 0
		if position.y < 0:
			position.y = viewport_size.y
		elif position.y > viewport_size.y:
			position.y = 0
	
	# 修改轨迹记录逻辑
	trail_positions[0] = global_position
	
	# 优化轨迹采样
	trail_sample_distance += (direction * current_speed * delta).length()
	if trail_sample_distance >= BASE_SEGMENT_GAP * 0.5:  # 减小采样间距，增加平滑度
		trail_positions.insert(1, trail_positions[0])
		trail_sample_distance = 0.0
		
		if trail_positions.size() > (body_segments.size() + 1) * 2:  # 适当增加轨迹点数量
			trail_positions.pop_back()
	update_body()
	
	

# 穿越屏幕到另一边
func traverse(position):
	if position.x > GameManager.SHOW_RANGE.x:
		print(position.x)
		global_position = Vector2(0, position.y)
	

func update_body():
	var target_positions = trail_positions
	
	
	while body_segments.size() < (target_positions.size() - 1) / 2:  # 调整身体段数量计算
		var new_segment = BODY_SEGMENT.instantiate()
		get_parent().add_child(new_segment)
		# 直接将新段放置在正确的位置，避免突然从屏幕中间蹦到尾部
		var segment_index = body_segments.size()
		var target_idx = (segment_index + 1) * 2
		if target_idx < target_positions.size():
			new_segment.global_position = target_positions[target_idx]
		body_segments.append(new_segment)
	
	for i in range(body_segments.size()):
		var target_idx = (i + 1) * 2  # 每个身体段对应两个轨迹点
		if target_idx < target_positions.size():
			# 使用lerp进行平滑插值
			var target_pos = target_positions[target_idx]
			var current_pos = body_segments[i].global_position
			
			# 检查是否发生穿越（如果当前位置和目标位置的距离超过屏幕尺寸的一半，则认为发生了穿越）
			var distance = abs(current_pos.x - target_pos.x)
			var distance_y = abs(current_pos.y - target_pos.y)
			
			if distance > viewport_size.x / 2 or distance_y > viewport_size.y / 2:
				body_segments[i].global_position = target_pos
			else:
				body_segments[i].global_position = body_segments[i].global_position.lerp(
					target_pos, 
					interpolation_weight
				)
			# 计算并平滑设置旋转，因为身体是圆形，此处可以忽略
			#if target_idx + 1 < target_positions.size():
				#var look_dir = (target_positions[target_idx - 1] - target_pos).normalized()
				#var target_rotation = look_dir.angle() + TAU / 4
				#body_segments[i].rotation = lerp_angle(
					#body_segments[i].rotation,
					#target_rotation,
					#interpolation_weight
				#)

func grow():
	# 获取最后一个位置
	var last_position = trail_positions.back()
	# 增加轨迹长度实现生长效果，重复最后一个位置
	trail_positions.push_back(last_position)

# 碰撞层级控制：
# 身体段：只在层2可见，但不检测任何层（mask=0）
# 头部：检测层2的碰撞（mask=2）
# 碰撞检测逻辑：
# 当头部进入身体段的碰撞区域时触发_on_area_entered
# 通过is_in_group("body")确认碰撞对象是身体段
func _on_area_entered(area):
	# 碰撞检测（当碰到食物时）
	if area.is_in_group("food"):
		# 消除吃到的食物
		# 开启手柄震动
		Input.start_joy_vibration(0,0.5,0.5,1)
		area.queue_free()
		# 生成新的食物
		GameManager.apple_eaten.emit()
		GameManager.add_source(1)
		GameManager.play_eat()
		# 蛇的长度增加
		grow()
		## 与身体发生碰撞，单人模式时结束游戏，多人模式时跳过此判断
	elif area.is_in_group("body"):
		if area.get_index() > initial_length + 2:
			GameManager.play_die()
			GameManager.lose_game()			
