extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -4
var GRAVITY = 9

# Vars to emulate z-axis
var z = 0  #our z position
var height = -8  #The height of the player
var zfloor : float = 0  #The floor the player will land on
var jump = false

var zspeed = 0

@onready var room_node = $'..'
@onready var colshape_node = shape_owner_get_owner(0) # Returns the first child node which contains a collision shape

func instance_place(x, y, group):
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape_rid = colshape_node.shape
	query.transform = room_node.global_transform.translated(Vector2(x, y)) * colshape_node.transform
	for i in space.intersect_shape(query):
		if i["collider"].is_in_group(group):
			return i["collider"]
	return null

func _physics_process(delta):
	# Get the input direction and handle the direction of the raycast
	var direction = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	velocity = direction * 100
	
	if direction != Vector2.ZERO:
		$RayCast2D.target_position = direction * 24

	# Handle jump.
	if Input.is_action_pressed("ui_accept"):
		jump = true
	
	if jump == true:
		zspeed = JUMP_VELOCITY
	
	if z < zfloor:
		if jump == true:
			zspeed += GRAVITY
		else:
			zspeed = GRAVITY
		GRAVITY += .2
	
	if GRAVITY > 9:
		GRAVITY = 9
	
	if z + zspeed >= zfloor:
		z = zfloor
		GRAVITY = 0
		zspeed = 0
		jump = false
		z_index = 0
	
	move_and_slide()
	
	if $RayCast2D.is_colliding():
		var block = $RayCast2D.get_collider()
		if z <= block.height+block.z or height+z >= block.z:
			add_collision_exception_with(block)
		else:
			remove_collision_exception_with(block)
	
	if instance_place(position.x, position.y, "Blocks"):
		var block = instance_place(position.x, position.y, "Blocks")
		#If we're higher than the block, send the shadow to the top of that block
		if block.z >= z:
			zfloor = block.height+block.z;
			z_index = 1
		#Send shadow to the ground
		else:
			zfloor = 0;
	else:
		zfloor = 0
	
	#Hit the bottom of a block
	if instance_place(position.x, position.y, "Blocks"):
		var block = instance_place(position.x, position.y, "Blocks")
		#This checks are for making sure we're below the block
		if block and block.z < height+zspeed and zfloor >= block.z:
			if zspeed <= 0 and z > block.z: #z > block.z ensures this change of zSpeed doesn't occur when we're above a block
				zspeed += GRAVITY
				GRAVITY += .3
	
	
	z += zspeed
	$Sprite2D.position.y = z
	$CanvasLayer/Label.text = "z: " + str(z) + "\nZspeed: " + str(zspeed) + "\nGravity: " + str(GRAVITY)
	
	$Camera2D.position.y = lerp($Camera2D.position.y, zfloor, $Camera2D.position_smoothing_speed * delta)
