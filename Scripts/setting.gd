extends Control

@onready var musicBtn = $VBoxContainer/HBoxContainer/MusicBtn
@onready var audioBtn = $VBoxContainer/HBoxContainer2/AudioBtn
@onready var chineseBtn = $VBoxContainer/HBoxContainer3/ChineseBtn
@onready var englishBtn = $VBoxContainer/HBoxContainer3/EnglishBtn
@onready var joystickBtn = $VBoxContainer/HBoxContainer4/JoystickBtn

func _ready() -> void:
	if GameManager.play_music:
		musicBtn.text = "开"
	else:
		musicBtn.text = "关"
	if GameManager.play_audio:
		audioBtn.text = "开"
	else:
		audioBtn.text = "关"		
	if GameManager.open_joystick:
		joystickBtn.text = "开"
	else:
		joystickBtn.text = "关"

func _on_back_btn_pressed() -> void:
	GameManager.load_start_ui()


func _on_music_btn_pressed() -> void:
	if GameManager.play_music:
		musicBtn.text = "关"
		GameManager.audioBgmPlayer.stop()
	else:
		musicBtn.text = "开"
		GameManager.audioBgmPlayer.play()
	GameManager.play_music = !GameManager.play_music


func _on_audio_btn_pressed() -> void:
	if GameManager.play_audio:
		audioBtn.text = "关"
	else:
		audioBtn.text = "开"		
	GameManager.play_audio = !GameManager.play_audio


func _on_chinese_btn_pressed() -> void:
	pass # Replace with function body.


func _on_english_btn_pressed() -> void:
	pass # Replace with function body.


func _on_joystick_btn_pressed() -> void:
	if GameManager.open_joystick:
		joystickBtn.text = "关"
	else:
		joystickBtn.text = "开"
	GameManager.open_joystick = !GameManager.open_joystick
