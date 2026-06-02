extends CanvasLayer

@onready var magazine = $Magazine
@onready var maze_game = $MazeGame

func _ready():
	# Position magazine offscreen initially
	magazine.position.y = get_viewport().get_visible_rect().size.y
	maze_game.modulate.a = 0
	maze_game.hide()
	
	# Connect to coupon book in the scene
	var coupon_book = get_node_or_null("../CouponBook")
	if coupon_book:
		coupon_book.interacted.connect(_on_coupon_book_interacted)
		
	magazine.coupon_selected.connect(_on_coupon_selected)
	maze_game.maze_finished.connect(_on_maze_finished)
	magazine.close_requested.connect(_on_magazine_closed)
	
	_setup_hud()

var hud_panel: Panel
var day_label: Label
var debt_label: Label
var gold_label: Label
var retries_label: Label

func _setup_hud():
	hud_panel = Panel.new()
	hud_panel.position = Vector2(20, 20)
	hud_panel.size = Vector2(200, 120)
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(180, 100)
	
	day_label = Label.new()
	debt_label = Label.new()
	gold_label = Label.new()
	retries_label = Label.new()
	
	gold_label.add_theme_color_override("font_color", Color.GOLD)
	debt_label.add_theme_color_override("font_color", Color.RED)
	
	vbox.add_child(day_label)
	vbox.add_child(debt_label)
	vbox.add_child(gold_label)
	vbox.add_child(retries_label)
	
	hud_panel.add_child(vbox)
	add_child(hud_panel)

func _process(_delta):
	if is_instance_valid(day_label):
		day_label.text = "Day: %d" % GameState.current_day
		debt_label.text = "Debt: $%d" % int(GameState.debt)
		gold_label.text = "Gold: $%d" % int(GameState.gold)
		
		var max_r = GameState.get_max_retries()
		var used_r = GameState.daily_state["retries_used"]
		retries_label.text = "Retries: %d / %d" % [max_r - used_r, max_r]

func _on_coupon_book_interacted():
	var player = get_node_or_null("../Player")
	if player:
		player.set_movement_locked(true)
	
	magazine.refresh_magazine()
	
	# Slide up magazine
	var tween = create_tween()
	var target_y = get_viewport().get_visible_rect().size.y - magazine.size.y
	tween.tween_property(magazine, "position:y", target_y, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func _on_coupon_selected(coupon_id):
	if not GameState.can_try_coupon(coupon_id):
		print("Cannot try coupon ", coupon_id, " again today!")
		return
		
	GameState.try_coupon(coupon_id)
	
	# Fade in maze game
	maze_game.show()
	var tween = create_tween()
	tween.tween_property(maze_game, "modulate:a", 1.0, 0.3)
	maze_game.start_game(coupon_id)

func _on_maze_finished(won: bool, coupon_id: int):
	# Fade out maze game
	var tween = create_tween()
	tween.tween_property(maze_game, "modulate:a", 0.0, 0.3)
	tween.tween_callback(maze_game.hide)
	
	if won:
		print("Inventory updated: Added coupon ", coupon_id)
		GameState.record_successful_coupon(coupon_id)
		magazine.refresh_magazine()
	else:
		if GameState.can_try_coupon(coupon_id):
			print("Failed coupon ", coupon_id, ", but can try again.")
		else:
			print("Coupon ", coupon_id, " destroyed! No retries left.")
		magazine.refresh_magazine()

func _on_magazine_closed():
	var tween = create_tween()
	tween.tween_property(magazine, "position:y", get_viewport().get_visible_rect().size.y, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	var player = get_node_or_null("../Player")
	if player:
		player.set_movement_locked(false)
