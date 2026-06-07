extends CanvasLayer

var ingredients_paths = [
	"res://data/ingredients/dragon_scale.tres",
	"res://data/ingredients/human_dust.tres",
	"res://data/ingredients/unicorn_hair.tres"
]

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var btn = Button.new()
	btn.text = "DEBUG: Auto-Fill Cart & Checkout"
	btn.position = Vector2(20, 20)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(_on_debug_pressed)
	add_child(btn)
	
	var reset_btn = Button.new()
	reset_btn.text = "DEBUG: Reset Save to Day 2"
	reset_btn.position = Vector2(20, 70)
	reset_btn.add_theme_font_size_override("font_size", 24)
	reset_btn.add_theme_color_override("font_color", Color.RED)
	reset_btn.pressed.connect(_on_reset_pressed)
	add_child(reset_btn)

func _on_debug_pressed():
	# Fill cart with 10 random ingredients
	for i in range(10):
		var path = ingredients_paths[randi() % ingredients_paths.size()]
		var ing = load(path)
		GameState.cart_items.append(ing)
		
	# Go to checkout
	SceneLoader.load_scene("res://Scenes/Checkout/checkout_minigame_3d.tscn")

func _on_reset_pressed():
	GameState.reset_game(GameState.daily_interest)
	# Optional: change to main menu if you have one, or just reload current scene
	SceneLoader.load_scene("res://Scenes/StartGame/StartPage.tscn")
