extends CharacterBody3D
class_name ShoppingWizard

@onready var movementC = $MovementComponent
@onready var wizard = $WizardMesh
@onready var camera = $Camera3D
@onready var leaningC = $LeaningComponent
@onready var leftCast = $LeftCast
@onready var rightCast = $RightCast

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

func attempt_grab_left():
	grab("left")

func attempt_grab_right():
	grab("right")

func grab(direction):
	if direction == "left":
		if leftCast.is_colliding():
			var colliding_object = leftCast.get_collider()
			var item = colliding_object.get_parent().item
			print("You have picked up one ", item.item_name, ". It costs: ", item.price)
	else:
		if rightCast.is_colliding():
			var colliding_object = rightCast.get_collider()
			var item = colliding_object.get_parent().item
			print("You have picked up one ", item.item_name, ". It costs: ", item.price)
	
func _on_left_lean_button_mouse_entered():
	leaningC.lean(-1)


func _on_right_lean_button_mouse_entered():
	leaningC.lean(1)


func _on_lean_button_mouse_exited():
	leaningC.lean(0)
