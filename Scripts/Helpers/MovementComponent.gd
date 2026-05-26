extends Node
class_name MovementComponent

@export var parent = Node2D

@export var base_rotation_speed := 5.0
@export var base_acceleration := 200.0
@export var base_max_speed := 500.0

var cur_max_speed = base_max_speed
var cur_acceleration = base_acceleration
var cur_rotation_speed = base_rotation_speed

var target_velocity = Vector3.ZERO

func move(delta):
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("Forward"):
		direction.x += 1
	
	if Input.is_action_pressed("Backward"):
		direction.x -= 1
	
	if Input.is_action_pressed("Left"):
		direction.z -= 1
	
	if Input.is_action_pressed("Right"):
		direction.z += 1
	
	if Input.is_action_just_pressed("Jump") and parent.is_on_floor():
		direction.y += 10
	
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		# Setting the basis property will affect the rotation of the node.
		parent.basis = Basis.looking_at(direction)
	
	target_velocity.x = direction.x * cur_acceleration * delta
	target_velocity.z = direction.z * cur_acceleration * delta
	
	if not parent.is_on_floor():
		target_velocity.y = target_velocity.y - (9.8 * delta)
	
	parent.velocity = target_velocity
