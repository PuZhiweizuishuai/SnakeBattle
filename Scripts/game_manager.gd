extends Node

# 分数
var source = 0

# 玩家吃到苹果
signal apple_eaten 
# 皮肤切换
signal skin_change(index: int)

var play_music = true
var play_audio = true
var language : String = "ZH"
var open_joystick = true
# 网络模式 0 ENetMultiplayerPeer 低延迟
# 1 WebSocketMultiplayerPeer 兼容 web
var network_mod = 0

var audioBgmPlayer

var audioPlayer

var bgm = preload("res://AssetBundle/Audio/BGM.mp3")

var eat = preload("res://AssetBundle/Audio/Eat.mp3")

var die = preload("res://AssetBundle/Audio/Die.mp3")

var click = preload("res://AssetBundle/Audio/click.wav")

# 显示范围
const SHOW_RANGE = Vector2(1920, 1080)

const FOOD_MARGIN = 40

# 单人游戏模式
# 0 边界模式 1 自由模式
var SingleGameMode : int = 0

# 单人游戏皮肤
# 0 蓝，1 黄, 2 少女
var SingleGameSkin : int = 0

# BGM
func _audioBgmPlayer() -> void:
	audioBgmPlayer = AudioStreamPlayer.new()
	bgm.loop = true
	audioBgmPlayer.stream = bgm
	audioBgmPlayer.autoplay = true
	# 开启立体声
	audioBgmPlayer.mix_target = AudioStreamPlayer.MIX_TARGET_CENTER
	# audioBgmPlayer.loop = true
	add_child(audioBgmPlayer)

	
# 音效
func _audioPlayer() -> void:
	audioPlayer = AudioStreamPlayer.new()
	add_child(audioPlayer)

func _ready() -> void:
	# 设置调试状态按照720P运行
	if Engine.is_editor_hint() or OS.has_feature("debug"):
		get_window().set_size(Vector2(1280, 720))
	start_game()
	# 初始化背景音乐播放器
	_audioBgmPlayer()
	# 创建一个音效播放器
	_audioPlayer()

func play_eat() -> void:
	if play_audio:
		audioPlayer.stream = eat
		audioPlayer.play()

func play_die() -> void:
	if play_audio:
		audioPlayer.stream = die
		audioPlayer.play()


func play_click() -> void:
	if play_audio:
		audioPlayer.stream = click
		audioPlayer.play()

func add_source(x: int) -> void:
	source = source + x	
	get_node("/root/SinglePlayer/UI/SourceLabel").text = "分数：" + str(source)

func start_game() -> void:
	source = 0
	

func restart_game() -> void:
	get_tree().change_scene_to_file("res://Scenes/single_player.tscn")
	start_game()
	
func lose_game() -> void:
	get_tree().change_scene_to_file("res://Scenes/lose_scene.tscn")

# 加载单人模式
func load_single_player_borderless_mode():
	get_tree().change_scene_to_file("res://Scenes/single_game_ui.tscn")
	
# 加载主界面
func load_start_ui():
	get_tree().change_scene_to_file("res://Scenes/start_ui.tscn")

# 加载多人模式
func load_multiplayer_first_ui():
	get_tree().change_scene_to_file("res://Scenes/multiplayer_first_ui.tscn")
	
func load_multiplayer_second_ui():
	get_tree().change_scene_to_file("res://Scenes/multiplayer_second_ui.tscn")

func load_multiplayer_game():
	get_tree().change_scene_to_file("res://Scenes/multiplayer_game.tscn")
	
func load_setting():
	get_tree().change_scene_to_file("res://Scenes/setting.tscn")


func load_about():
	get_tree().change_scene_to_file("res://Scenes/about.tscn")
