extends Node2D

const FOOD = preload("res://Scenes/food.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.apple_eaten.connect(_on_food_collected)
	spawn_food()

func spawn_food():
	var new_food = FOOD.instantiate()
	new_food.position = Vector2(
		randf_range(GameManager.FOOD_MARGIN, GameManager.SHOW_RANGE.x - GameManager.FOOD_MARGIN),
		randf_range(GameManager.FOOD_MARGIN, GameManager.SHOW_RANGE.y - GameManager.FOOD_MARGIN)
	)
	add_child(new_food)

func _on_food_collected():
	call_deferred("spawn_food")
	
