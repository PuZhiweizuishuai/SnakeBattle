extends Node2D

@onready var players = $Players
@onready var HEAD = preload("res://Scenes/multiplayer_head.tscn")
@onready var FOOD = preload("res://Scenes/food.tscn")

func _ready():
	NetworkGameManager.eat_food.connect(spawn_food)
	# 给players节点下增加玩家
	for player in NetworkGameManager.players:
		add_player(player.id, player.skin_index)
	
	# 如果是服务器，生成初始食物
	if multiplayer.is_server():
		spawn_initial_food()

func add_player(id: int, skin: int) -> void:
	var head = HEAD.instantiate()
	head.name = str(id)
	
	# 使用同步的初始位置和方向
	if NetworkGameManager.snakeInfoMap.has(str(id)):
		head.position = NetworkGameManager.snakeInfoMap[str(id)].init_position
		head.direction = NetworkGameManager.snakeInfoMap[str(id)].direction
	
	players.add_child(head)
	head.init_snake_skin(skin)

# 服务器生成初始食物
func spawn_initial_food():
	if not multiplayer.is_server():
		return
	
	for i in range(5):  # 生成5个初始食物
		var food_pos = Vector2(
			randf_range(50, GameManager.SHOW_RANGE.x - 50),
			randf_range(50, GameManager.SHOW_RANGE.y - 50)
		)
		# 使用RPC同步食物位置到所有客户端
		NetworkGameManager.spawn_network_food.rpc(food_pos)

# 生成单个食物 - 所有客户端都会执行这个函数
func spawn_food(food_position: Vector2):
	var food = FOOD.instantiate()
	food.position = food_position
	$Foods.add_child(food)
