extends Control
class_name UpgradeScreen

@onready var content_container = $VBoxContainer/ContentContainer/ColorRect/MarginContainer
@onready var upgrades_btn = $VBoxContainer/TopBar/HBoxContainer/UpgradesBtn
@onready var coupons_btn = $VBoxContainer/TopBar/HBoxContainer/CouponsBtn
@onready var start_shopping_btn = $VBoxContainer/TopBar/HBoxContainer/StartShoppingBtn
@onready var header_label = $VBoxContainer/TopBar/HBoxContainer/HeaderLabel
@onready var maze_game_container = $MazeGameContainer

@onready var day_label = $VBoxContainer/BottomBar/HBoxContainer/DayLabel
@onready var gold_label = $VBoxContainer/BottomBar/HBoxContainer/GoldLabel
@onready var debt_label = $VBoxContainer/BottomBar/HBoxContainer/DebtLabel
@onready var pay_debt_btn = $VBoxContainer/BottomBar/HBoxContainer/PayDebtBtn

var upgrade_ui_scene = preload("res://Scenes/upgrade_ui.tscn")
var magazine_scene = preload("res://coupon_game/magazine.tscn")
var maze_minigame_scene = preload("res://coupon_game/maze_minigame.tscn")

var current_view: Control = null
var active_maze: Control = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GameState.save_current_scene(scene_file_path)
	
	upgrades_btn.pressed.connect(_on_upgrades_pressed)
	coupons_btn.pressed.connect(_on_coupons_pressed)
	start_shopping_btn.pressed.connect(_on_start_shopping_pressed)
	pay_debt_btn.pressed.connect(_on_pay_debt_pressed)
	
	# Open upgrades by default
	_on_upgrades_pressed()

func _process(_delta):
	day_label.text = "Day: %d" % GameState.current_day
	gold_label.text = "Gold: [img=16]res://Assets/gold_coin.png[/img]%d" % int(GameState.gold)
	debt_label.text = "Debt: [img=16]res://Assets/gold_coin.png[/img]%d" % int(GameState.debt)

func _on_pay_debt_pressed():
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


func clear_content():
	if current_view:
		current_view.queue_free()
		current_view = null

func animate_transition(new_view: Control, direction: int = 1):
	if current_view:
		var old_view = current_view
		var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
		# Poppy animation out
		tween.tween_property(old_view, "position:x", -800 * direction, 0.4)
		tween.parallel().tween_property(old_view, "modulate:a", 0.0, 0.2)
		tween.tween_callback(old_view.queue_free)
	
	current_view = new_view
	content_container.add_child(new_view)
	
	# Ensure the new view is set to fill the container correctly
	new_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	new_view.position.x = 800 * direction
	new_view.modulate.a = 0.0
	
	var in_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Poppy animation in
	in_tween.tween_property(new_view, "position:x", 0.0, 0.5)
	in_tween.parallel().tween_property(new_view, "modulate:a", 1.0, 0.3)

func _on_upgrades_pressed():
	header_label.text = "UPGRADES"
	var new_ui = upgrade_ui_scene.instantiate()
	animate_transition(new_ui, -1)
	
	# Adjust embedded UI
	var close_btn = new_ui.get_node_or_null("Panel/VBoxContainer/CloseButton")
	if close_btn:
		close_btn.hide()
	var panel = new_ui.get_node_or_null("Panel")
	if panel:
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.offset_left = 0
		panel.offset_top = 0
		panel.offset_right = 0
		panel.offset_bottom = 0

func _on_coupons_pressed():
	header_label.text = "COUPON MAGAZINE"
	var new_ui = magazine_scene.instantiate()
	animate_transition(new_ui, 1)
	
	var close_btn = new_ui.get_node_or_null("MarginContainer/VBoxContainer/HBoxContainer/CloseButton")
	if close_btn:
		close_btn.hide()
	
	new_ui.coupon_selected.connect(_on_coupon_selected)

func _on_coupon_selected(id: int):
	if not GameState.can_try_coupon(id):
		return
		
	active_maze = maze_minigame_scene.instantiate()
	maze_game_container.add_child(active_maze)
	
	active_maze.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(active_maze, "modulate:a", 1.0, 0.3)
	
	active_maze.maze_finished.connect(_on_maze_finished)
	active_maze.start_game(id)

func _on_maze_finished(won: bool, coupon_id: int, cancelled: bool = false):
	if won:
		GameState.record_successful_coupon(coupon_id)
	elif not cancelled:
		GameState.try_coupon(coupon_id)
		
	var tween = create_tween()
	tween.tween_property(active_maze, "modulate:a", 0.0, 0.3)
	tween.tween_callback(active_maze.queue_free)
	
	# Refresh current view if it is the magazine
	if current_view and current_view.has_method("refresh_magazine"):
		current_view.refresh_magazine()

func _on_start_shopping_pressed():
	get_tree().change_scene_to_file("res://Scenes/shopping.tscn")
