extends Node
class_name LeaningComponent

@export var parent: ShoppingWizard

var camera_target : Vector3
var wizard_target : Vector3

var base_camera_target : Vector3
var base_wizard_target : Vector3

func _ready():
	await get_tree().process_frame
	get_base_position()
	camera_target = base_camera_target
	wizard_target = base_wizard_target

func get_base_position():
	base_camera_target = parent.camera.position
	base_wizard_target = parent.wizard.position

func _process(delta):
	parent.wizard.position = parent.wizard.position.lerp(wizard_target, 10 * delta)
	parent.camera.position = parent.camera.position.lerp(camera_target, 8 * delta)

func lean(direction):
	if direction == 1:
		camera_target = base_camera_target + Vector3(1, 0, 0)
		wizard_target = base_wizard_target + Vector3(1, 0, 0)
	elif direction == -1:
		camera_target = base_camera_target + Vector3(-1, 0, 0)
		wizard_target = base_wizard_target + Vector3(-1, 0, 0)
	else:
		camera_target = base_camera_target
		wizard_target = base_wizard_target
