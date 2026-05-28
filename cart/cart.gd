extends RigidBody3D

var is_driven = false
var driver = null

const DRIVE_FORCE = 30.0
const STEER_TORQUE = 15.0
const MAX_SPEED = 8.0

@onready var interact_area = $InteractArea

func interact():
	if is_driven:
		return
		
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if interact_area.overlaps_body(player):
			player.enter_cart(self)

func focus():
	# Optional: add outline or highlight logic
	pass

func unfocus():
	pass

func _physics_process(delta):
	if is_driven and driver:
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		
		if input_dir.y != 0:
			var force_dir = global_transform.basis * Vector3(0, 0, input_dir.y)
			apply_central_force(force_dir * DRIVE_FORCE)
			
			if input_dir.x != 0:
				# Reverse steering when going backwards
				var steer_sign = -1.0 if input_dir.y < 0 else 1.0
				apply_torque(Vector3(0, input_dir.x * steer_sign * STEER_TORQUE, 0))
				
		if input_dir == Vector2.ZERO:
			apply_central_force(-linear_velocity * 2.0)
			apply_torque(-angular_velocity * 2.0)
			
		if linear_velocity.length() > MAX_SPEED:
			linear_velocity = linear_velocity.normalized() * MAX_SPEED
