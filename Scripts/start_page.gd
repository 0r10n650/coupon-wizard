extends Control
class_name StartPage

const tutorial_scene_path = "res://Scenes/tutorial.tscn"

const jordo_scene = preload("res://coupon_game/coupon_game_test.tscn")
const o_scene = preload("res://Scenes/shopping.tscn")
const checkout_scene = preload("res://checkout_minigame/checkout_minigame_3d.tscn")
const carpy_scene = preload("res://tests/shoppingfordummies.tscn")

@onready var debug_container = $DebugContainer

func _ready():
	if debug_container:
		debug_container.hide()

func _on_start_button_pressed():
	if GameState.has_save_file():
		get_tree().change_scene_to_file(GameState.last_scene_path)
	else:
		print("First time play! Loading tutorial (placeholder path)...")
		var error = get_tree().change_scene_to_file(tutorial_scene_path)
		if error != OK:
			print("Tutorial scene not found, falling back to shopping scene.")
			get_tree().change_scene_to_file("res://Scenes/shopping.tscn")

func _on_debug_toggle_pressed():
	if debug_container:
		debug_container.visible = !debug_container.visible

func _on_jordos_button_pressed():
	get_tree().change_scene_to_packed(jordo_scene)

func _on_o_button_pressed():
	get_tree().change_scene_to_packed(o_scene)

func _on_checkout_game_pressed():
	get_tree().change_scene_to_packed(checkout_scene)

func _on_carpy_demo_pressed():
	get_tree().change_scene_to_packed(carpy_scene)
