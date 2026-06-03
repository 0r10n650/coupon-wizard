extends Control

signal maze_finished(won: bool, coupon_id: int, cancelled: bool)

@onready var cursor_tracker = $CursorTracker
@onready var start_button = $StartButton

var is_playing = false
var current_coupon = -1
var active_maze_instance: Node = null
var time_left: float = 0.0
var timer_label: Label = null
var trail_line: Line2D = null

var maze_scenes = [
	preload("res://coupon_game/mazes/maze_star.tscn"),
	preload("res://coupon_game/mazes/maze_rect.tscn"),
	preload("res://coupon_game/mazes/maze_triangle.tscn"),
	preload("res://coupon_game/mazes/maze_hexagon.tscn"),
	preload("res://coupon_game/mazes/maze_circle.tscn"),
	preload("res://coupon_game/mazes/maze_complex.tscn")
]

func _ready():
	cursor_tracker.hide()
	
	timer_label = Label.new()
	timer_label.position = Vector2(400, 20)
	timer_label.add_theme_font_size_override("font_size", 32)
	add_child(timer_label)
	
	# Create and configure the trail line for mouse tracking
	trail_line = Line2D.new()
	trail_line.width = 4.0
	trail_line.default_color = Color(1.0, 0.84, 0.0, 0.8) # Gold
	trail_line.joint_mode = Line2D.LINE_JOINT_ROUND
	trail_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.84, 0.0, 0.1)) # Fade out at the start of the trail
	grad.set_color(1, Color(1.0, 0.4, 0.0, 0.9))   # Vibrant orange/gold at the cursor
	trail_line.gradient = grad
	
	trail_line.z_index = 5
	add_child(trail_line)
	
func start_game(coupon_id: int):
	current_coupon = coupon_id
	is_playing = false
	cursor_tracker.hide()
	start_button.show()
	
	if trail_line != null:
		trail_line.clear_points()
		trail_line.default_color = Color(1.0, 0.84, 0.0, 0.8)
		var grad = Gradient.new()
		grad.set_color(0, Color(1.0, 0.84, 0.0, 0.1))
		grad.set_color(1, Color(1.0, 0.4, 0.0, 0.9))
		trail_line.gradient = grad
	
	time_left = GameState.get_maze_time_limit()
	timer_label.text = "Time: %.1f" % time_left
	timer_label.modulate = Color.WHITE
	
	# Determine maze type based on coupon_id
	var maze_type = (coupon_id - 1) % 6
	load_maze(maze_type)

func load_maze(type: int):
	if active_maze_instance != null:
		active_maze_instance.queue_free()
		
	active_maze_instance = maze_scenes[type].instantiate()
	add_child(active_maze_instance)
	move_child(active_maze_instance, 0) # Move to back so UI is on top
	
	var walls_area = active_maze_instance.get_node("Walls")
	var goal_area = active_maze_instance.get_node("Goal/GoalArea")
	var start_pos = active_maze_instance.get_node("StartPos")
	
	walls_area.area_entered.connect(_on_walls_hit)
	goal_area.area_entered.connect(_on_goal_reached)
	
	start_button.position = start_pos.position - start_button.size / 2.0

func _process(delta):
	if is_playing:
		cursor_tracker.global_position = get_global_mouse_position()
		
		# Trace mouse movement in local coordinates
		if trail_line != null:
			var current_pos = get_local_mouse_position()
			if trail_line.points.size() == 0 or trail_line.points[-1].distance_to(current_pos) > 2.0:
				trail_line.add_point(current_pos)
		
		time_left -= delta
		if time_left <= 0:
			time_left = 0
			is_playing = false
			if trail_line != null:
				trail_line.default_color = Color(0.5, 0.5, 0.5, 0.8) # Turn gray on timeout
				trail_line.gradient = null
			maze_finished.emit(false, current_coupon, false)
			
		timer_label.text = "Time: %.1f" % time_left
		if time_left < 3.0:
			timer_label.modulate = Color.RED
		else:
			timer_label.modulate = Color.WHITE

func _on_start_button_pressed():
	is_playing = true
	start_button.hide()
	cursor_tracker.global_position = get_global_mouse_position()
	cursor_tracker.show()
	
	if trail_line != null:
		trail_line.clear_points()
		trail_line.default_color = Color(1.0, 0.84, 0.0, 0.8)
		var grad = Gradient.new()
		grad.set_color(0, Color(1.0, 0.84, 0.0, 0.1))
		grad.set_color(1, Color(1.0, 0.4, 0.0, 0.9))
		trail_line.gradient = grad
		trail_line.add_point(get_local_mouse_position())

func _on_back_button_pressed():
	if is_playing:
		is_playing = false
		maze_finished.emit(false, current_coupon, false)
	else:
		maze_finished.emit(false, current_coupon, true)

func _on_walls_hit(area):
	if is_playing and area == cursor_tracker:
		is_playing = false
		if trail_line != null:
			trail_line.default_color = Color(1.0, 0.2, 0.2, 0.8) # Turn red on failure
			trail_line.gradient = null
		maze_finished.emit(false, current_coupon, false)

func _on_goal_reached(area):
	if is_playing and area == cursor_tracker:
		is_playing = false
		if trail_line != null:
			trail_line.default_color = Color(0.2, 1.0, 0.2, 0.8) # Turn green on success
			trail_line.gradient = null
		maze_finished.emit(true, current_coupon, false)
