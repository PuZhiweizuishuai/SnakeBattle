extends TouchScreenButton

# 定义脚本可移动范围
const DARG_RADIUS : float = 28.0

# 判断是否与当前屏幕进行交互，默认-1表示未发生交互
var finger_index : int = -1

# 记录鼠标拖动时的偏移量
var drag_offset : Vector2

# 记录初始化位置
@onready var rest_pos = global_position

func _input(event: InputEvent) -> void:
	# 判断是不是触屏事件
	var st = event as InputEventScreenTouch
	if st:
		if st.pressed and finger_index == -1:
			var global_pos = st.position * get_canvas_transform()
			var local_pos = global_pos * get_global_transform()
			# print(local_pos)
			var rect = Rect2(Vector2.ZERO, texture_normal.get_size())
			# 判断触摸是否是在交互区域
			if rect.has_point(local_pos):
				# 按下
				drag_offset = global_pos - global_position
				finger_index = st.index
		elif not st.pressed and st.index == finger_index:
			# 松开
			finger_index = -1
			# 将按钮归位
			global_position = rest_pos
	# 获取屏幕拖拽事件
	var sd = event as InputEventScreenDrag
	if sd and sd.index == finger_index:
		var wish_pos = sd.position * get_canvas_transform() - drag_offset
		# 限制移动范围
		var movement = (wish_pos - rest_pos).limit_length(DARG_RADIUS)
		#拖动
		global_position = rest_pos + movement
		movement /= DARG_RADIUS
		print(movement)
		
