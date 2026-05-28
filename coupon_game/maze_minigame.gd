extends Control

signal maze_finished(won: bool, coupon_id: int)

@onready var cursor_tracker = $CursorTracker
@onready var start_button = $StartButton

var is_playing = false
var current_coupon = -1
var active_maze_instance: Node = null

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
	
func start_game(coupon_id: int):
	current_coupon = coupon_id
	is_playing = false
	cursor_tracker.hide()
	start_button.show()
	
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

func _process(_delta):
	if is_playing:
		cursor_tracker.global_position = get_global_mouse_position()

func _on_start_button_pressed():
	is_playing = true
	start_button.hide()
	cursor_tracker.global_position = get_global_mouse_position()
	cursor_tracker.show()

func _on_back_button_pressed():
	if is_playing:
		is_playing = false
		maze_finished.emit(false, current_coupon)
	else:
		maze_finished.emit(false, current_coupon)

func _on_walls_hit(area):
	if is_playing and area == cursor_tracker:
		is_playing = false
		maze_finished.emit(false, current_coupon)

func _on_goal_reached(area):
	if is_playing and area == cursor_tracker:
		is_playing = false
		maze_finished.emit(true, current_coupon)
