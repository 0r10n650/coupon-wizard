extends CharacterBody3D
class_name ShoppingWizard

@onready var movementC = $MovementComponent
@onready var wizard = $WizardMesh
@onready var camera = $Camera3D
@onready var leaningC = $LeaningComponent

func _physics_process(delta):
	movementC.move(delta)
	move_and_slide()


func _on_left_lean_button_mouse_entered():
	leaningC.lean(-1)


func _on_right_lean_button_mouse_entered():
	leaningC.lean(1)


func _on_lean_button_mouse_exited():
	leaningC.lean(0)
