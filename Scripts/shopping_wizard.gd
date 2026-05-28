extends CharacterBody3D
class_name ShoppingWizard

@onready var movementC = $MovementComponent
@onready var wizard = $WizardMesh
@onready var camera = $Camera3D
@onready var leaningC = $LeaningComponent
@onready var leftCast = $LeftCast
@onready var rightCast = $RightCast

func _physics_process(delta):
	movementC.move(delta)
	move_and_slide()

func attempt_grab_left():
	grab("left")

func attempt_grab_right():
	grab("right")

func grab(direction):
	if direction == "left":
		pass
	else:
		pass
	
func _on_left_lean_button_mouse_entered():
	leaningC.lean(-1)


func _on_right_lean_button_mouse_entered():
	leaningC.lean(1)


func _on_lean_button_mouse_exited():
	leaningC.lean(0)
