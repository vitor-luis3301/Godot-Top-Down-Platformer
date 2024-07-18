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
var height = -24  #The height of the player
var zfloor : float = 0  #The floor the player will land on
var jump = false #If we are jumping or not

var zspeed = 0 #Our velocity in the z axis

func instance_place(group):
	var bodies : Array
	for i in $Area2D.get_overlapping_bodies():
		if i.is_in_group(group):
			bodies.append(i)
	
	if bodies.size() > 0:
		return bodies[0]
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
	
	if zspeed > 2.5:
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
		
		#Same thing, but for Half-blocks
		if block.is_in_group("Half-Blocks"):
			add_collision_exception_with(block)
		
		if fmod(block.height / -16, 1) != 0 and (block.height - z) / 16 > -1:
			add_collision_exception_with(block)
	
	#Check if we're above the block
	if instance_place("Blocks"):
		var block = instance_place("Blocks")
		#If we're higher than the block, send the shadow to the top of that block
		if block.z >= z:
			zfloor = block.height+block.z;
			z_index = 1
		#Send shadow to the ground
		else:
			zfloor = 0;
	else:
		zfloor = 0
	
	#Same thing but for half-blocks
	for i in $Area2D.get_overlapping_bodies():
		if i.is_in_group("Hlaf-Blocks") or (fmod(i.height / -16, 1) != 0 and (i.height - z) / 16 > -1):
			if i.z >= z:
				zfloor = i.height+i.z;
				z_index = 1
			else:
				zfloor = 0;
			
	#Hit the bottom of a block
	if instance_place("Blocks"):
		var block = instance_place("Blocks")
		#This checks are for making sure we're below the block
		if block and block.z > z+height+zspeed and zfloor >= block.z:
			if zspeed <= 0 and z > block.z: #z > block.z ensures this change of zSpeed doesn't occur when we're above a block
				zspeed = GRAVITY
	
	#Do I really need to explain what this does?
	move_and_slide()
	#Yeah? I-... I do?
	#Well, just know that this functions is the one that actually moves the player, ok? Ok.
	
	#Change values accordingly
	z += zspeed
	$Sprite2D.position.y = z
	$CanvasLayer/Label.text = "z: " + str(z) + "\nZspeed: " + str(zspeed) + "\nGravity: " + str(GRAVITY)
	$Polygon2D.position.y = zfloor
	
	if direction.x != 0:
		if direction.x < 0:
			$Sprite2D.flip_h = true
		else:
			$Sprite2D.flip_h = false
	
	#Make the camera focus on the player's sprite
	$Camera2D.position.y = lerp($Camera2D.position.y, zfloor, $Camera2D.position_smoothing_speed * delta)