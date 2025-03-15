extends CharacterBody2D

@onready var coyoteTimer = $CoyoteTimer
@onready var jumpBuffer = $JumpBuffer
@onready var ray = $RayCast2D

#General variables
var SPEED = 100.0
var MAX_JUMP_VELOCITY : float 
var MIN_JUMP_VELOCITY : float
var GRAVITY = 0.2

var MAX_JUMP_HEIGHT = 2.25 #The highest point of our jump
var MIN_JUMP_HEIGHT = .25 #The lowest point that our jump can be
var JUMP_DURATION = 1 #How long is the jump going to be

# Vars to emulate z-axis
var z = 0  #our z position
var height = -18  #The height of the player
var zfloor : float = 0  #The floor the player will land on
var jump = false #If we are jumping or not

var zspeed = 0 #Our velocity in the z axis


func ray_instance_place(group):
	var objects_collide = [] #The colliding objects go here.
	while ray.is_colliding():
		var obj = ray.get_collider() #get the next object that is colliding.
		if obj.is_in_group(group):
			objects_collide.append( obj ) #add it to the array.
		ray.add_exception( obj ) #add to ray's exception. That way it could detect something being behind it.
		ray.force_raycast_update() #update the ray's collision query.

	#after all is done, remove the objects from ray's exception.
	for obj in objects_collide:
		ray.remove_exception( obj )
	
	return objects_collide

func instance_place(group):
	var bodies : Array = []
	for i in $Area2D.get_overlapping_bodies():
		if i.is_in_group(group):
			bodies.append(i)
	
	if bodies.size() > 0:
		return bodies
	else:
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
	velocity = direction * SPEED
	
	#handle the direction of the raycast
	if direction != Vector2.ZERO:
		ray.target_position = direction * 16
	
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
	if ray.is_colliding():
		var blocks = ray_instance_place("Blocks")
		blocks.sort_custom(func (a, b): return a.z > b.z)
		
		for block in blocks:
			#If we are either above or below it, we shouldn't collide with it
			if z <= block.height+block.z or height+z >= block.z:
				add_collision_exception_with(block)
			#Otherwise, we do
			else:
				remove_collision_exception_with(block)
			
			if fmod(block.height / -16, 1) != 0 and (block.height - z) / 16 > -1:
				add_collision_exception_with(block)
	
	#Check if we're inside the block's collision
	if instance_place("Blocks"):
		var blocks = instance_place("Blocks")
		blocks.sort_custom(func (a, b): return a.z > b.z)
		
		#If we're higher or lower than any block, send the shadow to the top of that block or the floor
		if blocks.size() > 1:
			for i in range(0, blocks.size()):
				if blocks[i].height+blocks[i].z >= z:
					zfloor = blocks[i].height+blocks[i].z;
					z_index = 1
		elif blocks[0].z >= z:
			zfloor = blocks[0].height+blocks[0].z;
			z_index = 1
		else:
			zfloor = 0
	else:
		zfloor = 0;
	# Change z and zfloor for half blocks
	for i in $Area2D.get_overlapping_bodies():
		if fmod(i.height / -16, 1) != 0 and (i.height - z) / 16 > -1:
			if i.z >= z:
				zfloor = i.height+i.z;
				z_index = 1
	# When something is detected as being a Half-block, the player goes up instantly,
			
	# Hit the bottom of any block
	var groups = ["Blocks", "Slopes", "Half-Blocks", "Stairs"]
	for i in groups:
		if instance_place(i):
			var blocks = instance_place(i)
			blocks.sort_custom(func (a, b): return a.z > b.z)
			
			for j in range(0, blocks.size()):
				var block = blocks[j] if blocks.size() > 1 else blocks[0]
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
		
	$Sprite2D.position.y = z # to get the ilusion of the player jumping
	$CanvasLayer/Label.text ="FPS: " + str(Engine.get_frames_per_second()) + "\nz: " + str(z) + "\nZfloor: " + str(zfloor) + "\nZspeed: " + str(zspeed) # print vars to the screen
	$Polygon2D.position.y = zfloor # change the position of the shadow
	
	# Flip the player's sprite according to it's direction
	if direction.x != 0:
		if direction.x < 0:
			$Sprite2D.flip_h = true
		else:
			$Sprite2D.flip_h = false
	
	#Make the camera focus on the player's sprite
	if !jump and z > -72:
		$Camera2D.position.y = lerp($Camera2D.position.y-2, zfloor, $Camera2D.position_smoothing_speed * delta)
	
	if z <= -72:
		$Camera2D.position.y = lerp($Camera2D.position.y-2, z, $Camera2D.position_smoothing_speed * delta)
