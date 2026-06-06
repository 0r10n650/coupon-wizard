extends CanvasLayer

var target_scene_path: String = ""

func _ready():
	hide()
	set_process(false)

func load_scene(path: String):
	target_scene_path = path
	show()
	
	# Wait two frames to ensure the screen actually renders before starting the load
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Start threaded load
	ResourceLoader.load_threaded_request(path)
	set_process(true)

func _process(_delta):
	if target_scene_path == "":
		set_process(false)
		return
		
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false)
		
		# Wait one more frame before instantiating to ensure everything is flushed
		await get_tree().process_frame 
		
		var packed_scene = ResourceLoader.load_threaded_get(target_scene_path)
		get_tree().change_scene_to_packed(packed_scene)
		hide()
		target_scene_path = ""
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		print("Failed to load scene: ", target_scene_path)
		hide()
		target_scene_path = ""
		set_process(false)
