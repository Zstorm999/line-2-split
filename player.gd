extends CharacterBody3D

@export var walk_speed: float = 2

var gravity: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity") \
	* ProjectSettings.get_setting("physics/3d/default_gravity_vector")

func _physics_process(delta: float) -> void:
	
	var move_direction = Input.get_vector(
			"move_left",
			"move_right",
			"move_up",
			"move_down"
	)
	velocity.x += move_direction.x * walk_speed
	velocity.z += move_direction.y * walk_speed
	
	# slide horizontal velocityé
	velocity.x *= 0.9
	velocity.z *= 0.9
	
	velocity += gravity * delta
	
	move_and_slide()
