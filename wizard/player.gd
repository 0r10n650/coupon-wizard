extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002

@onready var head = $Head
@onready var interact_ray = $Head/SpringArm3D/Camera3D/InteractRaycast
@onready var interact_label = $CrosshairUI/InteractLabel

@export_group("Animations")
@export var animation_player: AnimationPlayer
@export var idle_anim: String = "wiz_anim_lib/idle"
@export var run_anim: String = "wiz_anim_lib/run"
@export var jump_anim: String = "wiz_anim_lib/jump"
@export var anim_blend_time: float = 0.2

var current_anim: String = ""

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var can_move = true
var current_focused_object = null

var in_cart_mode: bool = false
var current_cart = null

@onready var right_arm_ik = $"WizIK/Crouch Idle/Skeleton3D/RightArmIK"
@onready var left_arm_ik = $"WizIK/Crouch Idle/Skeleton3D/LeftArmIK"
@onready var right_leg_ik = $"WizIK/Crouch Idle/Skeleton3D/RightLegIK"
@onready var left_leg_ik = $"WizIK/Crouch Idle/Skeleton3D/LeftLegIK"

func _set_ik_influence(ik_node, value: float):
	if not ik_node:
		return
	
	# Set active state based on influence
	if "active" in ik_node:
		ik_node.active = (value > 0.0)
		
	# Set influence/interpolation properties
	if "influence" in ik_node:
		ik_node.influence = value
	if "interpolation" in ik_node:
		ik_node.interpolation = value
		
	print("[Player Script] Set IK node '", ik_node.name, "' influence to ", value, " (active: ", ik_node.get("active") if "active" in ik_node else "N/A", ")")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if interact_ray:
		interact_ray.add_exception(self)
		
	# Print check to confirm nodes are found
	print("[Player Script] Initializing IK nodes:")
	print("  - right_arm_ik: ", right_arm_ik)
	print("  - left_arm_ik: ", left_arm_ik)
	print("  - right_leg_ik: ", right_leg_ik)
	print("  - left_leg_ik: ", left_leg_ik)
		
	# Disable all IK by default when walking
	_set_ik_influence(right_arm_ik, 0.0)
	_set_ik_influence(left_arm_ik, 0.0)
	_set_ik_influence(right_leg_ik, 0.0)
	_set_ik_influence(left_leg_ik, 0.0)

func _process(_delta):
	if not can_move:
		if current_focused_object:
			if current_focused_object.has_method("unfocus"):
				current_focused_object.unfocus()
			current_focused_object = null
		if interact_label:
			interact_label.visible = false
		return

	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider != current_focused_object:
			if current_focused_object and current_focused_object.has_method("unfocus"):
				current_focused_object.unfocus()
			
			current_focused_object = collider
			
			if current_focused_object and current_focused_object.has_method("focus"):
				current_focused_object.focus()
		if interact_label:
			interact_label.visible = current_focused_object != null and current_focused_object.has_method("interact")
	else:
		if current_focused_object:
			if current_focused_object.has_method("unfocus"):
				current_focused_object.unfocus()
			current_focused_object = null
		if interact_label:
			interact_label.visible = false

func _input(event):
	if in_cart_mode:
		if event.is_action_pressed("interact"):
			exit_cart()
		return

	if not can_move:
		return
		
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, -PI/2, PI/2)
		
	if event.is_action_pressed("interact"):
		if interact_ray.is_colliding():
			var collider = interact_ray.get_collider()
			if collider and collider.has_method("interact"):
				collider.interact()

func _physics_process(delta):
	if in_cart_mode and current_cart:
		global_transform = current_cart.get_node("PlayerPushPosition").global_transform
		
		var cart_vel = current_cart.linear_velocity
		cart_vel.y = 0
		if cart_vel.length() > 0.5:
			_play_anim(run_anim)
		else:
			_play_anim(idle_anim)
		return

	if not can_move:
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
		_play_anim(jump_anim)
	else:
		if Input.is_action_just_pressed("ui_accept"): # Often mapped to Space by default
			velocity.y = JUMP_VELOCITY
			_play_anim(jump_anim)

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		if is_on_floor():
			_play_anim(run_anim)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		if is_on_floor():
			_play_anim(idle_anim)

	move_and_slide()
	
	# Push RigidBody3D objects (like the cart) when we walk into them
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider is RigidBody3D:
			var push_dir = -col.get_normal()
			push_dir.y = 0
			collider.apply_central_impulse(push_dir.normalized() * 0.5)
func _play_anim(anim_name: String):
	if not animation_player or current_anim == anim_name:
		return
	animation_player.play(anim_name, anim_blend_time)
	current_anim = anim_name

func set_movement_locked(locked: bool):
	can_move = !locked
	if locked:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func enter_cart(cart):
	in_cart_mode = true
	current_cart = cart
	add_collision_exception_with(cart)
	
	if right_arm_ik and left_arm_ik:
		var r_target = cart.get_node("RightHandTarget")
		var l_target = cart.get_node("LeftHandTarget")
		right_arm_ik.set("target_node", right_arm_ik.get_path_to(r_target))
		left_arm_ik.set("target_node", left_arm_ik.get_path_to(l_target))
		
		_set_ik_influence(right_arm_ik, 1.0)
		_set_ik_influence(left_arm_ik, 1.0)
	
	# Legs must be 0 influence in cart mode
	_set_ik_influence(right_leg_ik, 0.0)
	_set_ik_influence(left_leg_ik, 0.0)
		
	# Tell cart it is driven
	cart.is_driven = true
	cart.driver = self

func exit_cart():
	in_cart_mode = false
	if current_cart:
		remove_collision_exception_with(current_cart)
		current_cart.is_driven = false
		current_cart.driver = null
		current_cart = null
	
	# All arm and leg IK must be 0 influence when not in cart mode
	_set_ik_influence(right_arm_ik, 0.0)
	_set_ik_influence(left_arm_ik, 0.0)
	_set_ik_influence(right_leg_ik, 0.0)
	_set_ik_influence(left_leg_ik, 0.0)
