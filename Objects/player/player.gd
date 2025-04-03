extends CharacterBody2D

@onready var coyoteTimer = $CoyoteTimer
@onready var jumpBuffer = $JumpBuffer
@onready var ray = $RayCast2D

#General variables
var SPEED = 100.0
var MAX_JUMP_VELOCITY : float 
var MIN_JUMP_VELOCITY : float
var GRAVITY = 0.2

var MAX_JUMP_HEIGHT = 1.5 #The highest point of our jump
var MIN_JUMP_HEIGHT = .25 #The lowest point that our jump can be
var JUMP_DURATION = 1 #How long is the jump going to be

# Vars to emulate z-axis
var z = 0  #our z position
var height = -18  #The height of the player
var zfloor : float = 0  #The floor the player will land on
var jump = false #If we are jumping or not
var jump_count = 3

var coyoteTimeout := false
var canCoyote := false

var zspeed = 0 #Our velocity in the z axis

func _ready():
	MAX_JUMP_VELOCITY = -sqrt(2 * (2 * MAX_JUMP_HEIGHT / pow(JUMP_DURATION, 2)) * MAX_JUMP_HEIGHT)
	MIN_JUMP_VELOCITY = -sqrt(2 * (2 * MAX_JUMP_HEIGHT / pow(JUMP_DURATION, 2)) * MIN_JUMP_HEIGHT)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if canCoyote == true or jump_count > 0:
			#if space is pressed, apply velocity upwards
			coyoteTimer.stop()
			zspeed = MAX_JUMP_VELOCITY
			jump = true
			jump_count -= 1
			canCoyote = false
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
	if z < zfloor and canCoyote == false:
		zspeed += GRAVITY
	
	#If we're grounded, reset variables
	if z + zspeed >= zfloor:
		z = zfloor
		zspeed = 0
		jump = false
		jump_count = 3
		coyoteTimeout = true
		canCoyote = true
	
	#Coyote time and jump buffering
	if z < zfloor and !jump:
		if coyoteTimeout == true:
			coyoteTimer.start()
			coyoteTimeout = false
	
	if z >= zfloor and !jumpBuffer.is_stopped():
		jumpBuffer.stop()
		zspeed = MAX_JUMP_VELOCITY
		jump = true
		canCoyote = false
	
	#Do I really need to explain what this does?
	move_and_slide()
	#Yeah? I-... I do?
	#Well, just know that this functions is the one that actually moves the player, ok? Ok.
	
	#Change values accordingly
	z += zspeed
	$Sprite2D.z_index = -z/16
		
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
	if !jump:
		$Camera2D.position.y = lerp($Camera2D.position.y-2, zfloor, $Camera2D.position_smoothing_speed * delta)

func _on_coyote_timer_timeout():
	canCoyote = false
