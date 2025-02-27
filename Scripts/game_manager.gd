extends Node

# 分数
var source = 0

# 玩家吃到苹果
signal apple_eaten 

var audioBgmPlayer

var audioPlayer

var bgm = preload("res://AssetBundle/Audio/BGM.mp3")

var eat = preload("res://AssetBundle/Audio/Eat.mp3")

var die = preload("res://AssetBundle/Audio/Die.mp3")

# 显示范围
const SHOW_RANGE = Vector2(1920, 1080)

const FOOD_MARGIN = 40

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
	audioPlayer.stream = eat
	audioPlayer.play()

func play_die() -> void:
	audioPlayer.stream = die
	audioPlayer.play()


func add_source(x: int) -> void:
	source = source + x	
	get_node("/root/Main/UI/SourceLabel").text = "分数：" + str(source)

func start_game() -> void:
	source = 0
	

func restart_game() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
	start_game()
	
func lose_game() -> void:
	get_tree().change_scene_to_file("res://Scenes/lose_scene.tscn")

# 加载单人无边界模式
func load_single_player_borderless_mode():
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
