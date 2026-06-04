extends CharacterBody3D
class_name ShoppingWizard

@onready var movementC = $DriftingMovementComponent
@onready var wizard = $WizardMesh
@onready var camera = $Camera3D
@onready var leaningC = $LeaningComponent
@onready var leftCast = $LeftCast
@onready var rightCast = $RightCast
@onready var cur_inventory = $Inventory

var inventory : Array[inventory_item_2D]

var shopping_timer: float
var timer_ui: ShoppingTimerUI
var has_transitioned: bool = false

func _ready():
	shopping_timer = GameState.get_shopping_time_limit()
	
	timer_ui = ShoppingTimerUI.new(shopping_timer)
	timer_ui.timer_finished.connect(_on_timer_finished)
	add_child(timer_ui)

func _physics_process(delta):
	movementC.move(delta)
	move_and_slide()

func _on_timer_finished():
	if not has_transitioned:
		has_transitioned = true
		get_tree().change_scene_to_file("res://checkout_minigame/checkout_minigame_3d.tscn")

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			grab("left")
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			grab("right")


func grab(direction):
	var colliding_object = null
	
	if direction == "left":
		if leftCast.is_colliding():
			colliding_object = leftCast.get_collider()
	else:
		if rightCast.is_colliding():
			colliding_object = rightCast.get_collider()
	
	if colliding_object == null:
		return
	
	var col_ob_parent = colliding_object.get_parent()
	
	if not col_ob_parent is grocery_Item_3D:
		return
	
	var item = col_ob_parent.item
	
	if item == null:
		return
	
	if col_ob_parent.shelf_count > 0:
		cur_inventory.add_item(item)
		GameState.add_cart_item(item)
		col_ob_parent._get_item()
