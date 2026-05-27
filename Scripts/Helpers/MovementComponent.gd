extends Node
class_name MovementComponent

@export var parent = Node2D

@export var rotation_speed := 2.0
@export var acceleration := 15.0
@export var max_speed := 20.0

var current_speed = 0.0
var next_direction = Vector3.ZERO

func move(delta):
	
	if Input.is_action_pressed("Forward"):
		if current_speed < max_speed:
			current_speed += acceleration * delta
	
	if Input.is_action_pressed("Backward"):
		if current_speed > 0:
			current_speed -= acceleration * 4 * delta
	
	if Input.is_action_pressed("Left"):
		parent.rotate_y(rotation_speed * delta)
	
	if Input.is_action_pressed("Right"):
		parent.rotate_y(-rotation_speed * delta)
	
	if Input.is_action_just_pressed("Jump") and parent.is_on_floor():
		parent.velocity.y = 6
	
	if not parent.is_on_floor():
		parent.velocity.y = parent.velocity.y - (9.8 * delta)
	
	next_direction = -parent.transform.basis.z * current_speed
	parent.velocity.x = lerp(parent.velocity.x, next_direction.x, delta)
	parent.velocity.z = lerp(parent.velocity.z, next_direction.z, delta)
