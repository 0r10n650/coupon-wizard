extends Control

@onready var fireworks_container = $Fireworks

func _ready():
	$VBoxContainer/MenuButton.pressed.connect(_on_menu_pressed)
	$VBoxContainer/MenuButton.grab_focus()
	_spawn_fireworks()

func _on_menu_pressed():
	GameState.reset_game(0.10)
	SceneLoader.load_scene("res://Scenes/StartGame/StartPage.tscn")

func _spawn_fireworks():
	var timer = Timer.new()
	timer.wait_time = 0.4
	timer.autostart = true
	timer.timeout.connect(_on_firework_timer)
	add_child(timer)

func _on_firework_timer():
	var colors = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.PURPLE, Color.ORANGE, Color.CYAN]
	var firework = CPUParticles2D.new()
	firework.emitting = true
	firework.amount = 60
	firework.one_shot = true
	firework.explosiveness = 0.9
	firework.lifetime = 1.2
	firework.spread = 180.0
	firework.gravity = Vector2(0, 150)
	firework.initial_velocity_min = 150.0
	firework.initial_velocity_max = 300.0
	firework.scale_amount_min = 4.0
	firework.scale_amount_max = 8.0
	firework.color = colors[randi() % colors.size()]
	
	var screen_size = get_viewport_rect().size
	firework.position = Vector2(randf_range(100, screen_size.x - 100), randf_range(100, screen_size.y - 100))
	
	fireworks_container.add_child(firework)
	
	# Delete after lifetime
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(func(): if is_instance_valid(firework): firework.queue_free())
