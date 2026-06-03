extends CanvasLayer

@onready var panel_container = $CenterContainer/Control/PanelContainer

func _ready():
	hide_menu()
	# Optional: make the pause menu ignore the mouse when hidden
	# Though CanvasLayer visibility typically handles this

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		# Don't pause on the StartPage
		if get_tree().current_scene and get_tree().current_scene.name == "StartPage":
			return
			
		if visible:
			resume_game()
		else:
			pause_game()

var previous_mouse_mode: int

func pause_game():
	previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	show_menu()

func resume_game():
	Input.mouse_mode = previous_mouse_mode
	get_tree().paused = false
	hide_menu()

func show_menu():
	visible = true
	# Juicy animation
	panel_container.scale = Vector2(0.8, 0.8)
	panel_container.modulate.a = 0.0
	
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(panel_container, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_property(panel_container, "modulate:a", 1.0, 0.2)
	
	# Fade in background slightly
	$ColorRect.color.a = 0.0
	tween.tween_property($ColorRect, "color:a", 0.6, 0.2)

func hide_menu():
	visible = false

func _on_resume_button_pressed():
	resume_game()

func _on_quit_button_pressed():
	resume_game()
	get_tree().change_scene_to_file("res://Scenes/StartPage.tscn")
