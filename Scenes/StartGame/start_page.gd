extends Control
class_name StartPage

const tutorial_scene_path = "res://Scenes/tutorial.tscn"
const management_path = "res://Scenes/PrepareDay/management_screen.tscn"
const shopping_path = "res://Scenes/shopping.tscn"
const checkout_path = "res://checkout_minigame/checkout_minigame_3d.tscn"
const upgrade_path = "res://Scenes/upgrade_screen.tscn"

@onready var debug_container = $DebugContainer
@onready var interest_slider = %InterestSlider

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if debug_container:
		debug_container.hide()

func _on_start_button_pressed():
	if GameState.has_save_file():
		SceneLoader.load_scene(GameState.last_scene_path)
	else:
		print("First time play! Loading tutorial (placeholder path)...")
		if ResourceLoader.exists(tutorial_scene_path):
			SceneLoader.load_scene(tutorial_scene_path)
		else:
			print("Tutorial scene not found, falling back to shopping scene.")
			SceneLoader.load_scene("res://Scenes/shopping.tscn")

func _on_debug_toggle_pressed():
	if debug_container:
		debug_container.visible = !debug_container.visible

func _on_jordos_button_pressed():
	SceneLoader.load_scene(management_path)

func _on_o_button_pressed():
	SceneLoader.load_scene(shopping_path)

func _on_checkout_game_pressed():
	SceneLoader.load_scene(checkout_path)

func _on_go_to_shop_pressed():
	SceneLoader.load_scene(upgrade_path)

func _on_reset_save_pressed():
	GameState.reset_game(interest_slider.value / 100)
	GameState.save_game()


func _on_carpy_demo_pressed() -> void:
	SceneLoader.load_scene("res://Scenes/PrepareDay/orders_panel.tscn")
