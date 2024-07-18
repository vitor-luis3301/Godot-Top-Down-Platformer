extends StaticBody2D

@export var z = 0
@export var height : float = -16

func _ready():
	$Sprite2D.position.y = z
