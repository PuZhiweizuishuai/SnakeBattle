extends Node

# 多人游戏控制
# 端口
const PORT = 7000
# IP
const DEFAULT_SERVER_IP = "127.0.0.1"
# 最大连接数
const MAX_CONNECTIONS = 20

# 这将包含每个玩家的玩家信息，
# 密钥是每个玩家的唯一ID。
var players = {}

# 这是本地玩家信息。这应该在本地进行修改
# 在建立连接之前。它将传递给其他所有同行。
# 例如，“name”的值可以设置为玩家的值
# 在UI场景中输入。
var player_info = {"name": "Name"}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
