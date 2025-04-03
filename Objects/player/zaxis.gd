extends Area2D

@onready var ray = $"../RayCast2D"

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
	for i in get_overlapping_bodies():
		if i.is_in_group(group):
			bodies.append(i)
	
	if bodies.size() > 0:
		return bodies
	else:
		return null

func _physics_process(delta):
	#Check if we are above or below the block
	if ray.is_colliding():
		var blocks = ray_instance_place("Blocks")
		blocks.sort_custom(func (a, b): return a.z > b.z)
		
		for block in blocks:
			#If we are either above or below it, we shouldn't collide with it
			if owner.z <= block.height+block.z or owner.height+owner.z >= block.z:
				owner.add_collision_exception_with(block)
			#Otherwise, we do
			else:
				owner.remove_collision_exception_with(block)
			
			if fmod(block.height / -16, 1) != 0 and (block.height - owner.z) / 16 > -1:
				owner.add_collision_exception_with(block)
	
	#Check if we're inside the block's collision
	if instance_place("Blocks"):
		var blocks = instance_place("Blocks")
		blocks.sort_custom(func (a, b): return a.z > b.z)
		
		#If we're higher or lower than any block, send the shadow to the top of that block or the floor
		if blocks.size() > 1:
			for i in range(0, blocks.size()):
				if blocks[i].height+blocks[i].z >= owner.z:
					owner.zfloor = blocks[i].height+blocks[i].z;
		elif blocks[0].z >= owner.z:
			owner.zfloor = blocks[0].height+blocks[0].z;
		else:
			owner.zfloor = 0
	else:
		owner.zfloor = 0;
	# Change z and zfloor for half blocks
	for i in get_overlapping_bodies():
		if fmod(i.height / -16, 1) != 0 and (i.height - owner.z) / 16 > -1:
			if i.z >= owner.z:
				owner.zfloor = i.height+i.z;
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
				if block and block.z > owner.z+owner.height+owner.zspeed and owner.zfloor >= block.z:
					if owner.zspeed <= 0 and owner.z > block.z: #z > block.z ensures this change of zSpeed doesn't occur when we're above a block
						owner.zspeed = owner.GRAVITY
