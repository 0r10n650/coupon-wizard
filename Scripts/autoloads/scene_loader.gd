extends CanvasLayer

var _target_path: String = ""

func _ready():
	hide()

func load_scene(path: String):
	_target_path = path
	show()
	await get_tree().process_frame
	await get_tree().process_frame
	ResourceLoader.load_threaded_request(path)
	_poll()

func _poll():
	var status = ResourceLoader.load_threaded_get_status(_target_path)
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			_finish()
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
			_poll()
		_:
			push_error("SceneLoader: failed to load " + _target_path)
			hide()
			_target_path = ""
			if get_tree().current_scene.scene_file_path != "res://Scenes/StartGame/start_page.tscn":
				get_tree().change_scene_to_file("res://Scenes/StartGame/start_page.tscn")

func _finish():
	var packed = ResourceLoader.load_threaded_get(_target_path)
	_target_path = ""
	hide()
	
	if packed and packed is PackedScene:
		var instance = packed.instantiate()
		get_tree().current_scene.free()
		get_tree().root.add_child(instance)
		get_tree().current_scene = instance
	else:
		push_error("SceneLoader: failed to instantiate scene. Returning to start menu.")
		if get_tree().current_scene.scene_file_path != "res://Scenes/StartGame/start_page.tscn":
			get_tree().change_scene_to_file("res://Scenes/StartGame/start_page.tscn")
