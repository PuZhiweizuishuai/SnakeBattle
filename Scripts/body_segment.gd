extends Area2D

# 上一个身体
var prev_body = null
# 下一个身体
var next_body = null

@onready var body = $Sprite2D

# 身体之间的最小距离
@export var min_body_distance: float = 45.0

func _ready():
		# 蓝皮
	body.texture = load("res://AssetBundle/Sprites/Snak/sb0"+ str(GameManager.SingleGameSkin) +".png")
	add_to_group("body")
	$CollisionShape2D.disabled = false 

func set_skin(skin_index):
	body.texture = load("res://AssetBundle/Sprites/Snak/sb0"+ str(skin_index) +".png")


func is_head() -> bool:
	return prev_body == null
