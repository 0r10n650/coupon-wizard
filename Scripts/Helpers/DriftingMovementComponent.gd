extends Node
class_name DriftingMovementComponent

@export var parent: Node 

@export var rotation_speed := 3.0
@export var acceleration := 10.0
@export var braking := 30.0
@export var max_speed := 20.0
@export var friction := 0.5

@export var traction_fast := 0.05
@export var traction_slow := 0.8 

var current_speed = 0.0

func _ready():
	if not parent:
		parent = get_parent()

func move(delta):
	var gas = Input.get_axis("move_backward", "move_forward")
	var steer = Input.get_axis("move_right", "move_left")

	if gas > 0:
		current_speed += acceleration * delta
	elif gas < 0:
		current_speed -= braking * delta
	else:
		current_speed = move_toward(current_speed, 0, friction * delta)
		
	current_speed = clamp(current_speed, -max_speed / 2.0, max_speed)
	
	if abs(current_speed) > 0.5:
		var dir = 1 if current_speed > 0 else -1
		var turn_mult = clamp(abs(current_speed) / 5.0, 0.1, 1.0)
		parent.rotate_y(steer * rotation_speed * turn_mult * dir * delta)
		
	if Input.is_action_just_pressed("move_jump") and parent.is_on_floor():
		parent.velocity.y = 6.0
	
	if not parent.is_on_floor():
		parent.velocity.y -= 9.8 * delta

	var target_vel = -parent.transform.basis.z * current_speed
	var speed_pct = abs(current_speed) / max_speed
	var traction = lerp(traction_slow, traction_fast, speed_pct)
	
	if abs(steer) > 0:
		traction *= 0.5
		
	parent.velocity.x = lerp(parent.velocity.x, target_vel.x, traction)
	parent.velocity.z = lerp(parent.velocity.z, target_vel.z, traction)
