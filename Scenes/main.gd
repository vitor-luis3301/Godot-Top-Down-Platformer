extends Node2D

func _ready():
	print(fmod(-40.0 / -16.0, 1))

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
