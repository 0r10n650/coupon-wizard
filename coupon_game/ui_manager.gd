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
var debt_label: RichTextLabel
var gold_label: RichTextLabel
var retries_label: Label

func _setup_hud():
	hud_panel = Panel.new()
	hud_panel.position = Vector2(20, 20)
	hud_panel.size = Vector2(240, 200)
	hud_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(220, 180)
	
	day_label = Label.new()
	debt_label = RichTextLabel.new()
	debt_label.bbcode_enabled = true
	debt_label.fit_content = true
	debt_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	gold_label = RichTextLabel.new()
	gold_label.bbcode_enabled = true
	gold_label.fit_content = true
	gold_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	retries_label = Label.new()
	
	gold_label.add_theme_color_override("default_color", Color.GOLD)
	debt_label.add_theme_color_override("default_color", Color.RED)
	
	vbox.add_child(day_label)
	vbox.add_child(debt_label)
	vbox.add_child(gold_label)
	vbox.add_child(retries_label)
	
	var payoff_btn = Button.new()
	payoff_btn.text = "Pay Debt"
	payoff_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	payoff_btn.pressed.connect(_on_payoff_pressed)
	vbox.add_child(payoff_btn)
	
	hud_panel.add_child(vbox)
	add_child(hud_panel)

func _on_payoff_pressed():
	if GameState.gold > 0 and GameState.debt > 0:
		var amount = min(GameState.gold, GameState.debt)
		GameState.pay_debt(amount)
		if GameState.debt <= 0:
			_show_win_screen()

func _show_win_screen():
	var win_panel = Panel.new()
	win_panel.custom_minimum_size = Vector2(400, 200)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var title = Label.new()
	title.text = "VICTORY!"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = "You paid off all your debt!\nYou are a true Coupon Wizard!"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)
	
	var close_btn = Button.new()
	close_btn.text = "Keep Playing"
	close_btn.custom_minimum_size = Vector2(120, 40)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func(): win_panel.queue_free())
	vbox.add_child(close_btn)
	
	win_panel.add_child(vbox)
	add_child(win_panel)
	
	var vp_size = get_viewport().get_visible_rect().size
	win_panel.position = (vp_size - win_panel.custom_minimum_size) / 2.0

func _process(_delta):
	if is_instance_valid(day_label):
		day_label.text = "Day: %d" % GameState.current_day
		debt_label.text = "Debt: [img=16]res://Assets/gold_coin.png[/img]%d" % int(GameState.debt)
		gold_label.text = "Gold: [img=16]res://Assets/gold_coin.png[/img]%d" % int(GameState.gold)
		
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
