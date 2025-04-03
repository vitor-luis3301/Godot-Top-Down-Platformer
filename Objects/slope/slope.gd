extends StaticBody2D

@export var z = 0
@export var height = 0

@export var rotate = 0 # 1: left, 2: right, 3: up, 4: down

func _ready():
	$Sprite2D.position.y = z
	$Sprite2D.z_index = -z/16
	# implement rotate
	if rotate == 1:
		$Sprite2D.texture = load("res://Assets/slope_left_and_right.png")
		$Sprite2D.flip_h = true
	elif rotate == 2:
		$Sprite2D.texture = load("res://Assets/slope_left_and_right.png")
		$Sprite2D.flip_h = false
	elif rotate == 3:
		$Sprite2D.texture = load("res://Assets/slope_up.png")
		$Sprite2D.flip_h = false
	elif rotate == 4:
		$Sprite2D.texture = load("res://Assets/slope_down.png")
		$Sprite2D.flip_h = false
		
