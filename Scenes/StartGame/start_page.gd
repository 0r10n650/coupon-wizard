class_name StartPage
extends Control

const management_path = "res://Scenes/Management/management_screen.tscn"

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
		print("Starting game.")
		SceneLoader.load_scene(management_path)

func _on_reset_save_button_pressed() -> void:
	GameState.reset_game(interest_slider.value / 100)
	
func _on_select_scene(scene_name: String) -> void:
	SceneLoader.load_scene("res://Scenes/%s" % scene_name)

func _on_debug_toggle_pressed():
	if debug_container:
		debug_container.visible = !debug_container.visible
