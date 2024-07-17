extends CharacterBody2D

@onready var coyoteTimer = $CoyoteTimer
@onready var jumpBuffer = $JumpBuffer

#General variables
var SPEED = 300.0
var MAX_JUMP_VELOCITY : float 
var MIN_JUMP_VELOCITY : float
var GRAVITY = 0.2

var MAX_JUMP_HEIGHT = 2.25 #The highest point of our jump
var MIN_JUMP_HEIGHT = .25 #The lowest point that our jump can be
var JUMP_DURATION = 1 #How long is the jump going to be

# Vars to emulate z-axis
var z = 0  #our z position
var height = -8  #The height of the player
var zfloor : float = 0  #The floor the player will land on
var jump = false #If we are jumping or not

var zspeed = 0 #Our velocity in the z axis

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

func _ready():
	MAX_JUMP_VELOCITY = -sqrt(2 * (2 * MAX_JUMP_HEIGHT / pow(JUMP_DURATION, 2)) * MAX_JUMP_HEIGHT)
	MIN_JUMP_VELOCITY = -sqrt(2 * (2 * MAX_JUMP_HEIGHT / pow(JUMP_DURATION, 2)) * MIN_JUMP_HEIGHT)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if coyoteTimer.is_stopped() == false or z >= zfloor:
			#if space is pressed, apply velocity upwards
			coyoteTimer.stop()
			zspeed = MAX_JUMP_VELOCITY
			jump = true
		else:
			jumpBuffer.start()
	
	if event.is_action_released("ui_accept") and zspeed <= MIN_JUMP_VELOCITY:
		#if space is released before jump is completed, interupt jumping
		zspeed = MIN_JUMP_VELOCITY

func _physics_process(delta):
	# Get the input direction
	var direction = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	velocity = direction * 100
	
	#handle the direction of the raycast
	if direction != Vector2.ZERO:
		$RayCast2D.target_position = direction * 24
		
	#Do I really need to explain what this does?
	move_and_slide()
	#Yeah? I-... I do?
	#Well, just know that this functions is the one that actually moves the player, ok? Ok.
	
	#If we're not on the floor, apply gravity
	if z < zfloor:
		zspeed += GRAVITY
	
	#If we're grounded, reset variables
	if z + zspeed >= zfloor:
		z = zfloor
		zspeed = 0
		jump = false
		z_index = 0
	
	#Coyote time and jump buffering
	if !z + zspeed >= zfloor and !jump:
		coyoteTimer.start()
	
	if zspeed > 1.5:
		coyoteTimer.stop()
	
	if z >= zfloor and !jumpBuffer.is_stopped():
		jumpBuffer.stop()
		zspeed = MAX_JUMP_VELOCITY
		jump = true
	
	#Check if we are above or below the block
	if $RayCast2D.is_colliding():
		var block = $RayCast2D.get_collider()
		
		#If we are, we shouldn't collide with it
		if z <= block.height+block.z or height+z >= block.z:
			add_collision_exception_with(block)
		#Otherwise, we do
		else:
			remove_collision_exception_with(block)
	
	#Check if we're above the block
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
		if block and block.z > z+height+zspeed and zfloor >= block.z:
			if zspeed <= 0 and z > block.z: #z > block.z ensures this change of zSpeed doesn't occur when we're above a block
				zspeed = GRAVITY
	
	#Change values accordingly
	z += zspeed
	$Sprite2D.position.y = z
	$CanvasLayer/Label.text = "z: " + str(z) + "\nZspeed: " + str(zspeed) + "\nGravity: " + str(GRAVITY)
	$Polygon2D.position.y = zfloor
	
	#Make the camera focus on the player's sprite
	$Camera2D.position.y = lerp($Camera2D.position.y, zfloor, $Camera2D.position_smoothing_speed * delta)
