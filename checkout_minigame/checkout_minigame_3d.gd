extends Node3D

@export var debug_only_up: bool = false
@export var combo_time_limit: float = 2.0
@export var fire_combo_threshold: int = 20
@export var arrow_spacing: float = 3.0:
	set(value):
		arrow_spacing = value
		if is_node_ready() and arrow_anchor:
			for i in range(active_sprites.size()):
				if is_instance_valid(active_sprites[i]):
					active_sprites[i].position.x = i * arrow_spacing



@onready var price_label = $CanvasLayer/VBoxContainer2/PriceLabel
@onready var discount_label = $CanvasLayer/VBoxContainer/DiscountLabel
@onready var combo_bar = $CanvasLayer/VBoxContainer/ComboBar
@onready var combo_label = $CanvasLayer/ComboLabel
@onready var camera = $GameCamera3D
@onready var hit_particles = $HitParticles3D

var up_rune = preload("res://checkout_minigame/assets/coupon_icon_uparrow.png")
var down_rune = preload("res://checkout_minigame/assets/coupon_icon_downarrow.png")
var left_rune = preload("res://checkout_minigame/assets/coupon_icon_leftarrow.png")
var right_rune = preload("res://checkout_minigame/assets/coupon_icon_rightarrow.png")

var arrow_types = []
var arrow_queue = []
var active_sprites = []
var base_price = 100.00
var total_discount = 0.0
var combo_count = 0
var combo_timer = 0.0
enum GameState { WAITING_TO_START, INTRO_CUTSCENE, PLAYING, END_CUTSCENE }
var current_state: GameState = GameState.WAITING_TO_START
@onready var anim_player = $AnimationPlayer
var camera_shake_trauma = 0.0

var left_fire_particles: CPUParticles2D
var right_fire_particles: CPUParticles2D
@onready var arrow_anchor = $ArrowAnchor

func _ready():
	arrow_types = [
		{"name": "up", "texture": up_rune, "action": "ui_up"},
		{"name": "down", "texture": down_rune, "action": "ui_down"},
		{"name": "left", "texture": left_rune, "action": "ui_left"},
		{"name": "right", "texture": right_rune, "action": "ui_right"}
	]
	
	combo_bar.max_value = combo_time_limit
	combo_bar.value = combo_time_limit
	
	_setup_fire_particles()
	
	update_ui()
	play_start_cutscene()

func _setup_fire_particles():
	var screen_size = get_viewport().get_visible_rect().size
	
	left_fire_particles = _create_fire_emitter()
	left_fire_particles.position = Vector2(20, screen_size.y)
	left_fire_particles.emission_rect_extents = Vector2(20, screen_size.y / 2.0)
	$CanvasLayer.add_child(left_fire_particles)
	
	right_fire_particles = _create_fire_emitter()
	right_fire_particles.position = Vector2(screen_size.x - 20, screen_size.y)
	right_fire_particles.emission_rect_extents = Vector2(20, screen_size.y / 2.0)
	$CanvasLayer.add_child(right_fire_particles)

func _create_fire_emitter() -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.amount = 100
	particles.lifetime = 1.5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.direction = Vector2(0, -1)
	particles.gravity = Vector2(0, -100)
	particles.initial_velocity_min = 100
	particles.initial_velocity_max = 250
	particles.scale_amount_min = 5.0
	particles.scale_amount_max = 15.0
	particles.color = Color(1.0, 0.4, 0.0, 0.8)
	
	# Add a slight color ramp for fire effect
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 1.0, 0.2, 1.0)) # Yellow center
	gradient.add_point(0.4, Color(1.0, 0.4, 0.0, 1.0)) # Orange
	gradient.add_point(1.0, Color(1.0, 0.1, 0.0, 0.0)) # Red fading out
	particles.color_ramp = gradient
	
	return particles


func play_start_cutscene():
	current_state = GameState.INTRO_CUTSCENE
	combo_label.text = ""
	
	if anim_player and anim_player.has_animation("start_cutscene"):
		anim_player.play("start_cutscene")
		await anim_player.animation_finished
	
	current_state = GameState.WAITING_TO_START
	update_ui()

func start_game():
	current_state = GameState.PLAYING
	combo_count = 0
	total_discount = 0.0
	combo_timer = combo_time_limit
	combo_bar.scale = Vector2(1.0, 1.0)
	combo_bar.modulate = Color.WHITE
	arrow_queue.clear()
	active_sprites.clear()
	for child in arrow_anchor.get_children():
		child.queue_free()
		
	# Spawn initial 4 arrows
	for i in range(4):
		spawn_arrow()
	update_ui()

func spawn_arrow():
	var arrow_data = null
	if debug_only_up:
		arrow_data = arrow_types[0]
	else:
		arrow_data = arrow_types[randi() % arrow_types.size()]
		
	arrow_queue.push_back(arrow_data)
	
	var sprite = Sprite3D.new()
	sprite.texture = arrow_data["texture"]
	sprite.pixel_size = 0.002
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	var child_index = active_sprites.size()
	sprite.position = Vector3(child_index * arrow_spacing, 0, 0)
	
	arrow_anchor.add_child(sprite)
	active_sprites.push_back(sprite)

func _process(delta):
	if current_state == GameState.PLAYING and combo_count > 0:
		combo_timer -= delta
		combo_bar.value = combo_timer
		
		var time_ratio = combo_timer / combo_time_limit
		if time_ratio > 0.5:
			combo_bar.modulate = Color.GREEN.lerp(Color.YELLOW, (1.0 - time_ratio) * 2.0)
		else:
			combo_bar.modulate = Color.YELLOW.lerp(Color.RED, (0.5 - time_ratio) * 2.0)
			
		if time_ratio < 0.3:
			combo_bar.pivot_offset = combo_bar.size / 2.0
			var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.05
			combo_bar.scale = Vector2(pulse, pulse)
		else:
			combo_bar.scale = Vector2(1.0, 1.0)
			
		if combo_timer <= 0:
			drop_combo()

	# Process camera shake
	camera_shake_trauma = max(0.0, camera_shake_trauma - delta)
	var trauma_shake = camera_shake_trauma * camera_shake_trauma
	var continuous_shake = 0.0
	if combo_count > 10:
		continuous_shake = min((combo_count - 10) * 0.02, 1.0)
		
	var total_shake = min(trauma_shake + continuous_shake, 2.0)
	
	if total_shake > 0:
		var x_shake = randf_range(-total_shake, total_shake)
		var y_shake = randf_range(-total_shake, total_shake)
		camera.h_offset = x_shake
		camera.v_offset = y_shake
		# UI offset needs to be larger since it's in pixels, not 3D units
		$CanvasLayer.offset = Vector2(x_shake * 15.0, y_shake * 15.0)
	elif camera.h_offset != 0 or camera.v_offset != 0:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		$CanvasLayer.offset = Vector2.ZERO
		
	if current_state == GameState.PLAYING and total_discount >= 50.0:
		play_end_cutscene()

func play_end_cutscene():
	current_state = GameState.END_CUTSCENE
	
	for child in active_sprites:
		if is_instance_valid(child):
			child.queue_free()
	active_sprites.clear()
	
	if anim_player and anim_player.has_animation("end_cutscene"):
		anim_player.play("end_cutscene")
		await anim_player.animation_finished
	
	print("Minigame Complete! Total Discount: $", total_discount)

func drop_combo():
	combo_count = 0
	combo_timer = combo_time_limit
	combo_bar.value = 0
	combo_bar.scale = Vector2(1.0, 1.0)
	combo_bar.modulate = Color.WHITE
	combo_label.text = "Combo Broken!"
	
	var drop_tween = create_tween()
	drop_tween.tween_property(discount_label, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_CUBIC)
	
	left_fire_particles.emitting = false
	right_fire_particles.emitting = false
	camera_shake_trauma = 0.0

func hit_arrow():
	combo_count += 1
	combo_timer = combo_time_limit
	combo_bar.value = combo_timer
	
	var discount_increase = 0.5 + (0.1 * combo_count)
	total_discount += discount_increase
	
	hit_particles.restart()
	hit_particles.emitting = true
	
	camera_shake_trauma = min(camera_shake_trauma + 0.3 + (combo_count * 0.01), 1.5)
	
	var target_scale = 1.0 + min(combo_count * 0.05, 1.5)
	discount_label.pivot_offset = discount_label.size / 2.0
	var label_tween = create_tween()
	discount_label.scale = Vector2(target_scale + 0.5, target_scale + 0.5)
	label_tween.tween_property(discount_label, "scale", Vector2(target_scale, target_scale), 0.4).set_trans(Tween.TRANS_BOUNCE)
	
	# Juiciness: Combo label flash and pop
	combo_label.pivot_offset = combo_label.size / 2.0
	var combo_tween = create_tween()
	combo_label.scale = Vector2(1.5, 1.5)
	combo_label.modulate = Color.from_hsv(randf(), 0.8, 1.0) # Rainbow flash
	combo_tween.tween_property(combo_label, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BOUNCE)
	combo_tween.parallel().tween_property(combo_label, "modulate", Color.WHITE, 0.5)
	
	# Juiciness: Floating text
	var floating_text = Label.new()
	floating_text.text = "+$%.2f" % discount_increase
	floating_text.add_theme_color_override("font_color", Color.GOLD)
	floating_text.add_theme_font_size_override("font_size", 32 + min(combo_count, 20))
	$CanvasLayer.add_child(floating_text)
	
	# Start floating text at the center
	floating_text.position = Vector2(get_viewport().get_visible_rect().size.x / 2.0 - 50, get_viewport().get_visible_rect().size.y / 2.0)
	
	var float_tween = create_tween()
	var random_x = randf_range(-100, 100)
	float_tween.tween_property(floating_text, "position", floating_text.position + Vector2(random_x, -250), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	float_tween.parallel().tween_property(floating_text, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	float_tween.tween_callback(floating_text.queue_free)
	
	if combo_count >= fire_combo_threshold:
		left_fire_particles.emitting = true
		right_fire_particles.emitting = true
	
	arrow_queue.pop_front()
	var first_child = active_sprites.pop_front() if active_sprites.size() > 0 else null
	if first_child:
		var queue_tween = create_tween()
		queue_tween.set_parallel(true)
		queue_tween.tween_property(first_child, "position:y", first_child.position.y + 1.5, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		queue_tween.tween_property(first_child, "scale", Vector3(2.5, 2.5, 2.5), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		queue_tween.tween_property(first_child, "modulate", Color(1, 1, 1, 0), 0.3).set_delay(0.1)
		queue_tween.chain().tween_callback(first_child.queue_free)
	
	var move_tween = create_tween()
	move_tween.set_parallel(true)
	for i in range(active_sprites.size()):
		var child = active_sprites[i]
		move_tween.tween_property(child, "position:x", i * arrow_spacing, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	spawn_arrow()
	update_ui()

func _input(event):
	match current_state:
		GameState.WAITING_TO_START:
			if event.is_action_pressed("ui_accept"):
				start_game()
		GameState.PLAYING:
			if arrow_queue.is_empty():
				return
				
			var expected_action = arrow_queue[0]["action"]
			
			if event.is_action_pressed(expected_action):
				hit_arrow()
			elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
				drop_combo()

func update_ui():
	#price_label.text = "Total: $%.2f" % max(0, base_price - total_discount)
	discount_label.text = "Discount: -$%.2f" % total_discount
	if combo_count > 0:
		combo_label.text = "Combo x%d!" % combo_count
	elif current_state == GameState.WAITING_TO_START:
		combo_label.text = "Press SPACE to start"
