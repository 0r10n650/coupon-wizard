extends CharacterBody3D
class_name ShoppingWizard

@onready var movementC = $MovementComponent

func _physics_process(delta):
	movementC.move(delta)
	move_and_slide()
