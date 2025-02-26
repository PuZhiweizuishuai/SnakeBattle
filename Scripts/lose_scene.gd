extends Control



func _ready() -> void:
	# 加载分数
	$SourceLabel.text = "得分：" + str(GameManager.source)

# 重启游戏
func _on_restart_btn_button_down() -> void:
	GameManager.restart_game()
