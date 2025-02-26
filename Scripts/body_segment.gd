extends Area2D

# 上一个身体
var prev_body = null
# 下一个身体
var next_body = null

# 身体之间的最小距离
@export var min_body_distance: float = 45.0

func _ready():
	add_to_group("body")
	$CollisionShape2D.disabled = false 


func is_head() -> bool:
	return prev_body == null
