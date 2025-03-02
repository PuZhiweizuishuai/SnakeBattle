class_name UserData

var id: int
var name: String
var skin_index: int = 0

# 带类型提示的构造函数
func _init(p_id: int, p_name: String):
	id = p_id
	name = p_name

func set_skin(index: int):
	skin_index = index
