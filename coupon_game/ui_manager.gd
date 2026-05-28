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

func _on_coupon_book_interacted():
	var player = get_node_or_null("../Player")
	if player:
		player.set_movement_locked(true)
	
	# Slide up magazine
	var tween = create_tween()
	var target_y = get_viewport().get_visible_rect().size.y - magazine.size.y
	tween.tween_property(magazine, "position:y", target_y, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func _on_coupon_selected(coupon_id):
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
		magazine.remove_coupon(coupon_id)
	else:
		print("Coupon ", coupon_id, " destroyed!")
		magazine.remove_coupon(coupon_id)

func _on_magazine_closed():
	var tween = create_tween()
	tween.tween_property(magazine, "position:y", get_viewport().get_visible_rect().size.y, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	var player = get_node_or_null("../Player")
	if player:
		player.set_movement_locked(false)
