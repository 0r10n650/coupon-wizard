extends Node3D

func _ready():
	if get_tree().current_scene:
		GameState.save_current_scene(get_tree().current_scene.scene_file_path)
