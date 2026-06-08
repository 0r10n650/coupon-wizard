extends CharacterBody3D
class_name ShoppingWizard

@onready var movementC = $MovementComponent
@onready var wizard = $WizardMesh
@onready var camera = $Camera3D
@onready var leftCast = $LeftCast
@onready var rightCast = $RightCast
@onready var cur_inventory = $ScrollContainer/Inventory

@onready var anim_player = $"WizIK/Crouch Idle/AnimationPlayer"
@onready var right_leg_ik = $"WizIK/Crouch Idle/Skeleton3D/RightLegIK"
@onready var left_leg_ik = $"WizIK/Crouch Idle/Skeleton3D/LeftLegIK"

@onready var left_arm_ik_target = $WizIK/LeftArmIKTarget
@onready var right_arm_ik_target = $WizIK/RightArmIKTarget
@onready var left_leg_ik_target = $WizIK/LeftLegIKTarget
@onready var right_leg_ik_target = $WizIK/RightLegIKTarget

@onready var grab_left_target = $GrabLeftTarget
@onready var grab_right_target = $GrabRightTarget
@onready var left_reset_point = $LeftResetPoint
@onready var right_reset_point = $RightResetPoint
@onready var left_l_reset_point = $LeftLResetPoint
@onready var right_l_reset_point = $RightLResetPoint

@onready var orders_container = $OrdersContainer
var orders_shown: bool = false
var orders_tween: Tween

const ORDER_CARD_SCENE = preload("res://Scenes/Management/order_card.tscn")

var left_tween: Tween
var right_tween: Tween

var inventory : Array[inventory_item_2D]

var shopping_timer: float
var timer_ui: ShoppingTimerUI
var has_transitioned: bool = false


func _ready():
	shopping_timer = GameState.get_shopping_time_limit()
	
	timer_ui = ShoppingTimerUI.new(shopping_timer)
	timer_ui.timer_finished.connect(_on_timer_finished)
	add_child(timer_ui)
	
	left_leg_ik_target.global_position = left_l_reset_point.global_position
	right_leg_ik_target.global_position = right_l_reset_point.global_position
	left_arm_ik_target.global_position = left_reset_point.global_position
	right_arm_ik_target.global_position = right_reset_point.global_position
	
	_build_orders_display()
	# start hidden up top
	orders_container.position.y = -orders_container.size.y + 20  # just peek 20px

func _process(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	for card in orders_container.get_children():
		var card_rect = Rect2(
			Vector2(card.global_position.x, 0),  # check full vertical strip
			Vector2(card.size.x, 150)  # 150px tall hover zone at top
		)
		if card_rect.has_point(mouse_pos):
			_slide_card_down(card)
		else:
			_slide_card_up(card)

func _physics_process(delta):
	movementC.move(delta)
	move_and_slide()
	
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	
	if Input.is_action_pressed("move_forward"):
		if anim_player.current_animation != "wiz_anim_lib/run":
			anim_player.play("wiz_anim_lib/run", 0.2)
		right_leg_ik.influence = lerpf(right_leg_ik.influence, 0.0, delta * 10.0)
		left_leg_ik.influence = lerpf(left_leg_ik.influence, 0.0, delta * 10.0)
	else:
		if anim_player.current_animation != "wiz_anim_lib/idle":
			anim_player.play("wiz_anim_lib/idle", 0.2)
			
		if horizontal_speed > 0.5:
			right_leg_ik.influence = lerpf(right_leg_ik.influence, 1.0, delta * 10.0)
			left_leg_ik.influence = lerpf(left_leg_ik.influence, 1.0, delta * 10.0)
		else:
			right_leg_ik.influence = lerpf(right_leg_ik.influence, 0.0, delta * 10.0)
			left_leg_ik.influence = lerpf(left_leg_ik.influence, 0.0, delta * 10.0)

func _on_timer_finished():
	if not has_transitioned:
		has_transitioned = true
		SceneLoader.load_scene("res://Scenes/Checkout/checkout_minigame_3d.tscn")

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			grab("left")
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			grab("right")

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q or event.keycode == KEY_LEFT:
			grab("left")
		elif event.keycode == KEY_E or event.keycode == KEY_RIGHT:
			grab("right")


func grab(direction):
	var colliding_object = null
	var cast = leftCast if direction == "left" else rightCast
	
	if cast.is_colliding():
		colliding_object = cast.get_collider()
		
	if colliding_object == null:
		return
		
	var col_ob_parent = colliding_object.get_parent()
	
	if not col_ob_parent is grocery_Item_3D:
		return
		
	var item = col_ob_parent.item
	
	if item == null:
		return
		
	if col_ob_parent.shelf_count > 0:
		if direction == "left":
			if left_tween: left_tween.kill()
			left_tween = create_tween()
			var parent = left_arm_ik_target.get_parent()
			var grab_local = parent.to_local(grab_left_target.global_position)
			var reset_local = parent.to_local(left_reset_point.global_position)
			left_tween.tween_property(left_arm_ik_target, "position", grab_local, 0.05)
			left_tween.tween_property(left_arm_ik_target, "position", reset_local, 0.1)
		else:
			if right_tween: right_tween.kill()
			right_tween = create_tween()
			var parent = right_arm_ik_target.get_parent()
			var grab_local = parent.to_local(grab_right_target.global_position)
			var reset_local = parent.to_local(right_reset_point.global_position)
			right_tween.tween_property(right_arm_ik_target, "position", grab_local, 0.05)
			right_tween.tween_property(right_arm_ik_target, "position", reset_local, 0.1)
			
		cur_inventory.add_item(item)
		GameState.add_cart_item(item)
		col_ob_parent._get_item()

func _build_orders_display():
	for order in GameState.active_orders:
		var card = ORDER_CARD_SCENE.instantiate()
		orders_container.add_child(card)
		card.setup(order)
		card.set_meta("shown", false)
		await get_tree().process_frame  # wait for size to be calculated
		card.position.y = -card.size.y + 100

func _slide_card_down(card: Control):
	if card.get_meta("shown", false):
		return
	card.set_meta("shown", true)
	var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "position:y", 50, 0.3)

func _slide_card_up(card: Control):
	if not card.get_meta("shown", false):
		return
	card.set_meta("shown", false)
	var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(card, "position:y", -card.size.y + 100, 0.3)
