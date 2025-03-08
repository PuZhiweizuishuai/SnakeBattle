extends Control

@onready var ip = $VBoxContainer/ip

func _ready() -> void:
	ip.text = _get_local_ip()

func _on_back_btn_pressed() -> void:
	GameManager.load_start_ui()
	
# 获取本地IP地址
func _get_local_ip() -> String:
	var ip := ""
	for address in IP.get_local_addresses():
		if _is_valid(address):
			ip += address + "\n"
	return ip

# 验证IPv4地址
func _is_valid(address: String) -> bool:
	return !address.begins_with("127.") && !address.begins_with("fe80:") && !address.begins_with("0:")
