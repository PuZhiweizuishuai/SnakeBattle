class_name SnakeInfoData

var id: int
# 保存蛇的初始化位置
var init_position = Vector2(0,0)

var SPEED = 200.0            # 基础移动速度

const BASE_SEGMENT_GAP = 30       # 固定的基础间距

var current_speed = SPEED          # 当前实际速度

var trail_sample_distance = 0.0    # 轨迹采样距离累计器

var body_segments = []         # 存储身体段的数组

var trail_positions = []       # 记录头部移动轨迹

var direction = Vector2.RIGHT  # 初始移动方向


func _init() -> void:
	pass
	
# 随机出生点
func random_position():
	init_position = Vector2(
		randf_range(GameManager.FOOD_MARGIN, GameManager.SHOW_RANGE.x - GameManager.FOOD_MARGIN),
		randf_range(GameManager.FOOD_MARGIN, GameManager.SHOW_RANGE.y - GameManager.FOOD_MARGIN)
	)
