extends Node
class_name MovementComponent

@export var parent = Node2D

@export var base_rotation_speed := 2.0
@export var base_acceleration := 10.0
@export var base_max_speed := 20.0

var cur_max_speed = base_max_speed
var cur_acceleration = base_acceleration
var cur_rotation_speed = base_rotation_speed

var next_direction = Vector3.ZERO

func move(delta):
	
	if Input.is_action_pressed("Forward"):
		next_direction = -parent.transform.basis.z * base_max_speed
	
	if Input.is_action_pressed("Backward"):
		next_direction = Vector3.ZERO
	
	if Input.is_action_pressed("Left"):
		parent.rotate_y(cur_rotation_speed * delta)
	
	if Input.is_action_pressed("Right"):
		parent.rotate_y(-cur_rotation_speed * delta)
	
	if Input.is_action_just_pressed("Jump") and parent.is_on_floor():
		next_direction.y += 10
	
	if not parent.is_on_floor():
		next_direction.y = next_direction.y - (9.8 * delta)
	
	parent.velocity = parent.velocity.lerp(next_direction, delta)
