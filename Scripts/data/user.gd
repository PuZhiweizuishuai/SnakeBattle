class_name UserData

var id: int
var name: String
# 皮肤编号
var skin_index: int = 0
# 是否准备,0 未准备，1准备完成
var is_ready = 0

# 带类型提示的构造函数
func _init(p_id: int, p_name: String):
	id = p_id
	name = p_name

func set_skin(index: int):
	skin_index = index
	
func set_ready(ready: int):
	is_ready = ready
	
