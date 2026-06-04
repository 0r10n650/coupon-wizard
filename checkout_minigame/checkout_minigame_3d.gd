extends Node3D

@export var debug_only_up: bool = false
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
@onready var cine_camera = $CineCamera3D
@onready var vbox_container = $CanvasLayer/VBoxContainer
@onready var vbox_container_2 = $CanvasLayer/VBoxContainer2
@onready var hit_particles = $HitParticles3D

var up_rune = preload("res://checkout_minigame/assets/coupon_icon_uparrow.png")
var down_rune = preload("res://checkout_minigame/assets/coupon_icon_downarrow.png")
var left_rune = preload("res://checkout_minigame/assets/coupon_icon_leftarrow.png")
var right_rune = preload("res://checkout_minigame/assets/coupon_icon_rightarrow.png")
var click_sound = preload("res://checkout_minigame/assets/click.mp3")

@export var click_start_time: float = 0.0
@export var click_duration: float = 0.1
var click_timer_remaining: float = 0.0
var click_player: AudioStreamPlayer

var arrow_types = []
var arrow_queue = []
var active_sprites = []

var base_price: int = 0
var total_discount: float = 0.0

enum MinigameState { WAITING_TO_START, INTRO_CUTSCENE, PLAYING, END_CUTSCENE }
var current_state: MinigameState = MinigameState.WAITING_TO_START
@onready var anim_player = $AnimationPlayer
@onready var arrow_anchor = $ArrowAnchor

var checkout_timer = 0.0
var checkout_time_limit = 5.0
var max_visible_arrows = 1
var current_item_index = 0
var cart_items = []
var total_items = 0

var successful_items = []
var destroyed_items = []

var displayed_total: int = 0

func _ready():
	if get_tree().current_scene:
		GameState.save_current_scene(get_tree().current_scene.scene_file_path)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	arrow_types = [
		{"name": "up", "texture": up_rune, "action": "ui_up"},
		{"name": "down", "texture": down_rune, "action": "ui_down"},
		{"name": "left", "texture": left_rune, "action": "ui_left"},
		{"name": "right", "texture": right_rune, "action": "ui_right"}
	]
	
	click_player = AudioStreamPlayer.new()
	click_player.stream = click_sound
	add_child(click_player)
	
	cart_items = GameState.cart_items.duplicate()
	total_items = cart_items.size()
	if total_items == 0:
		# Fallback for testing without cart
		for i in range(5):
			cart_items.append({"price": 20})
		total_items = 5
	
	base_price = 0
	for item in cart_items:
		if item != null:
			var val = item.get("price")
			if val != null:
				base_price += int(round(val))
	
	checkout_time_limit = GameState.get_checkout_time_limit()
	combo_bar.max_value = checkout_time_limit
	combo_bar.value = checkout_time_limit
	
	max_visible_arrows = 1 + GameState.get_checkout_vision()
	
	update_ui()
	play_start_cutscene()

func play_start_cutscene():
	current_state = MinigameState.INTRO_CUTSCENE
	combo_label.text = ""
	
	if cine_camera:
		cine_camera.current = true
	if vbox_container:
		vbox_container.visible = false
	if vbox_container_2:
		vbox_container_2.visible = false
	
	if anim_player and anim_player.has_animation("start_cutscene"):
		anim_player.play("start_cutscene")
		await anim_player.animation_finished
	
	var response_anims = []
	if anim_player:
		for anim_name in anim_player.get_animation_list():
			if anim_name.begins_with("response_"):
				response_anims.append(anim_name)
	
	if not response_anims.is_empty():
		var random_anim = response_anims[randi() % response_anims.size()]
		anim_player.play(random_anim)
		await anim_player.animation_finished
	
	if camera:
		camera.current = true
	if vbox_container:
		vbox_container.visible = true
	if vbox_container_2:
		vbox_container_2.visible = true
		
	arrow_queue.clear()
	active_sprites.clear()
	for child in arrow_anchor.get_children():
		child.queue_free()
		
	for i in range(total_items):
		var arrow_data = arrow_types[0] if debug_only_up else arrow_types[randi() % arrow_types.size()]
		var item_icon = null
		if i < cart_items.size() and cart_items[i] != null:
			item_icon = cart_items[i].get("image")
			
		arrow_queue.push_back({
			"action": arrow_data["action"],
			"texture": arrow_data["texture"],
			"item_icon": item_icon
		})
	
	update_visible_arrows()
	
	current_state = MinigameState.WAITING_TO_START
	combo_label.text = "Press any arrow to start!"
	update_ui()

func start_game():
	current_state = MinigameState.PLAYING
	checkout_timer = checkout_time_limit
	combo_bar.max_value = checkout_time_limit
	combo_bar.value = checkout_timer
	combo_bar.scale = Vector2(1.0, 1.0)
	combo_bar.modulate = Color.WHITE
	combo_label.text = "Checkout!"
	
	update_ui()

func update_visible_arrows():
	var needed_sprites = min(max_visible_arrows, arrow_queue.size() - current_item_index)
	while active_sprites.size() < needed_sprites:
		var sprite_index = current_item_index + active_sprites.size()
		var arrow_data = arrow_queue[sprite_index]
		
		var sprite = Sprite3D.new()
		sprite.texture = arrow_data["texture"]
		sprite.pixel_size = 0.002
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		
		var child_index = active_sprites.size()
		sprite.position = Vector3(child_index * arrow_spacing, 0, 0)
		sprite.scale = Vector3.ZERO
		
		if arrow_data.get("item_icon"):
			var icon_sprite = Sprite3D.new()
			icon_sprite.texture = arrow_data["item_icon"]
			icon_sprite.pixel_size = 0.001 # slightly smaller than arrow
			icon_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			# Position slightly above the arrow
			icon_sprite.position = Vector3(0, 1.2, 0)
			sprite.add_child(icon_sprite)
		
		arrow_anchor.add_child(sprite)
		active_sprites.push_back(sprite)
		
		var spawn_tween = create_tween()
		spawn_tween.tween_property(sprite, "scale", Vector3(1, 1, 1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta):
	if click_timer_remaining > 0:
		click_timer_remaining -= delta
		if click_timer_remaining <= 0:
			click_player.stop()

	if current_state == MinigameState.PLAYING:
		checkout_timer -= delta
		combo_bar.value = checkout_timer
		
		var time_ratio = checkout_timer / checkout_time_limit
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
			
		if checkout_timer <= 0:
			combo_bar.value = 0
			# Destroy remaining items
			for i in range(current_item_index, total_items):
				destroyed_items.append(cart_items[i])
			play_end_cutscene()

func play_end_cutscene():
	current_state = MinigameState.END_CUTSCENE
	
	for child in active_sprites:
		if is_instance_valid(child):
			child.queue_free()
	active_sprites.clear()
	
	if anim_player and anim_player.has_animation("end_cutscene"):
		anim_player.play("end_cutscene")
		await anim_player.animation_finished
	
	_show_payment_ui()

func _show_payment_ui():
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(480, 360)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 12)
	
	var title = Label.new()
	title.text = "Checkout Complete"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var details_grid = GridContainer.new()
	details_grid.columns = 2
	details_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_grid.add_theme_constant_override("h_separation", 40)
	details_grid.add_theme_constant_override("v_separation", 8)
	
	var create_row = func(label_text: String, val_text: String, color_mode: int = 0):
		var lbl = Label.new()
		lbl.text = label_text
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var val = RichTextLabel.new()
		val.bbcode_enabled = true
		val.fit_content = true
		val.autowrap_mode = TextServer.AUTOWRAP_OFF
		val.size_flags_horizontal = Control.SIZE_SHRINK_END
		val.text = val_text.replace("$", "[img=24]res://Assets/gold_coin.png[/img]")
		if color_mode == 1:
			val.add_theme_color_override("default_color", Color.GOLD)
		elif color_mode == 2:
			val.add_theme_color_override("default_color", Color.RED)
		elif color_mode == 3:
			val.add_theme_color_override("default_color", Color.GREEN)
		details_grid.add_child(lbl)
		details_grid.add_child(val)
		
	var add_separator = func():
		var sep1 = HSeparator.new()
		sep1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sep2 = HSeparator.new()
		sep2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details_grid.add_child(sep1)
		details_grid.add_child(sep2)

	var successful_total = 0
	for item in successful_items:
		if item != null:
			var val = item.get("price")
			if val != null:
				successful_total += int(round(val))
			
	var destroyed_total = 0
	for item in destroyed_items:
		if item != null:
			var val = item.get("price")
			if val != null:
				destroyed_total += int(round(val))

	var discount_pct = GameState.get_total_discount_percent()
	var discount_amount = int(successful_total * (discount_pct / 100.0))
	var final_debt_added = (successful_total - discount_amount) + destroyed_total
	
	total_discount = discount_amount
	
	create_row.call("Cart Total", "$%d" % int(base_price))
	add_separator.call()
	
	create_row.call("Checked Out Items", "$%d" % successful_total, 3)
	create_row.call("Destroyed Items", "$%d" % destroyed_total, 2)
	create_row.call("Discount (%d%%)" % discount_pct, "-$%d" % discount_amount, 1)
	
	add_separator.call()
	create_row.call("Added to debt", "$%d" % final_debt_added)
	
	vbox.add_child(details_grid)
	
	var credit_btn = Button.new()
	credit_btn.text = " Pay with Credit Card ( %d)" % final_debt_added
	credit_btn.icon = preload("res://Assets/gold_coin.png")
	credit_btn.expand_icon = true
	credit_btn.add_theme_constant_override("icon_max_width", 24)
	credit_btn.custom_minimum_size = Vector2(0, 50)
	credit_btn.pressed.connect(func(): _process_payment(final_debt_added, discount_amount, panel))
	vbox.add_child(credit_btn)
	
	panel.add_child(vbox)
	$CanvasLayer.add_child(panel)
	
	var vp_size = get_viewport().get_visible_rect().size
	panel.position = (vp_size - panel.custom_minimum_size) / 2.0

func _process_payment(credit_amount: int, discount_amount: int, ui_panel: Control):
	GameState.gold += discount_amount # You still get cash back for the discount
	GameState.debt += credit_amount
	GameState.advance_day()
	
	ui_panel.queue_free()
	get_tree().change_scene_to_file("res://Scenes/upgrade_screen.tscn")

func advance_to_next_arrow(success: bool):
	if active_sprites.size() > 0:
		var first_child = active_sprites.pop_front()
		
		var queue_tween = create_tween()
		queue_tween.set_parallel(true)
		if success:
			queue_tween.tween_property(first_child, "position:y", first_child.position.y + 1.5, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			queue_tween.tween_property(first_child, "scale", Vector3(2.5, 2.5, 2.5), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			queue_tween.tween_property(first_child, "position:y", first_child.position.y - 1.5, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			queue_tween.tween_property(first_child, "scale", Vector3(0.1, 0.1, 0.1), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			queue_tween.tween_property(first_child, "modulate", Color.RED, 0.2)
			
		queue_tween.tween_property(first_child, "modulate:a", 0.0, 0.3).set_delay(0.1)
		queue_tween.chain().tween_callback(first_child.queue_free)
	
	current_item_index += 1
	
	if current_item_index >= total_items:
		play_end_cutscene()
		return
		
	var move_tween = create_tween()
	move_tween.set_parallel(true)
	for i in range(active_sprites.size()):
		var child = active_sprites[i]
		move_tween.tween_property(child, "position:x", i * arrow_spacing, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	update_visible_arrows()
	update_ui()

func hit_arrow():
	successful_items.append(cart_items[current_item_index])
	
	hit_particles.restart()
	hit_particles.emitting = true
	
	var item = cart_items[current_item_index]
	var item_price = 0
	if item != null:
		var val = item.get("price")
		if val != null:
			item_price = int(round(val))
		
	displayed_total += item_price
	var target_discount = float(item_price * (GameState.get_total_discount_percent() / 100.0))
	total_discount += target_discount
	
	var target_scale = 1.2
	discount_label.pivot_offset = discount_label.size / 2.0
	var label_tween = create_tween()
	discount_label.scale = Vector2(target_scale + 0.5, target_scale + 0.5)
	label_tween.tween_property(discount_label, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BOUNCE)
	
	# Floating text
	var floating_text = RichTextLabel.new()
	floating_text.bbcode_enabled = true
	floating_text.fit_content = true
	floating_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	var fs = 32
	floating_text.add_theme_font_size_override("normal_font_size", fs)
	
	var display_val = snapped(target_discount, 0.01)
	if int(round(display_val * 100)) % 100 == 0:
		floating_text.text = "+[img=%d]res://Assets/gold_coin.png[/img]%d" % [fs, int(round(display_val))]
	else:
		floating_text.text = "+[img=%d]res://Assets/gold_coin.png[/img]%.2f" % [fs, display_val]
	floating_text.add_theme_color_override("default_color", Color.GOLD)
	$CanvasLayer.add_child(floating_text)
	
	floating_text.position = Vector2(get_viewport().get_visible_rect().size.x / 2.0 - 50, get_viewport().get_visible_rect().size.y / 2.0)
	var float_tween = create_tween()
	var random_x = randf_range(-100, 100)
	float_tween.tween_property(floating_text, "position", floating_text.position + Vector2(random_x, -250), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	float_tween.parallel().tween_property(floating_text, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	float_tween.tween_callback(floating_text.queue_free)
	
	advance_to_next_arrow(true)

func miss_arrow():
	var item = cart_items[current_item_index]
	var item_price = 0
	if item != null:
		var val = item.get("price")
		if val != null:
			item_price = int(round(val))
		
	displayed_total += item_price
	destroyed_items.append(cart_items[current_item_index])
	
	var floating_text = Label.new()
	floating_text.text = "Destroyed!"
	floating_text.add_theme_font_size_override("font_size", 32)
	floating_text.add_theme_color_override("font_color", Color.RED)
	$CanvasLayer.add_child(floating_text)
	
	floating_text.position = Vector2(get_viewport().get_visible_rect().size.x / 2.0 - 50, get_viewport().get_visible_rect().size.y / 2.0)
	var float_tween = create_tween()
	var random_x = randf_range(-100, 100)
	float_tween.tween_property(floating_text, "position", floating_text.position + Vector2(random_x, -250), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	float_tween.parallel().tween_property(floating_text, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	float_tween.tween_callback(floating_text.queue_free)
	
	advance_to_next_arrow(false)

func _input(event):
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if current_state == MinigameState.WAITING_TO_START:
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			start_game()
			
	if current_state == MinigameState.PLAYING:
		if current_item_index >= total_items:
			return
			
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			var expected_action = arrow_queue[current_item_index]["action"]
			click_player.play(click_start_time)
			click_timer_remaining = click_duration
			
			if event.is_action_pressed(expected_action):
				hit_arrow()
			else:
				miss_arrow()

func update_ui():
	price_label.text = "[center]Total: [img=24]res://Assets/gold_coin.png[/img]%d[/center]" % displayed_total
	discount_label.text = "[center]Discount: -[img=24]res://Assets/gold_coin.png[/img]%d[/center]" % int(round(total_discount))
	if current_state == MinigameState.WAITING_TO_START:
		combo_label.text = "Match the arrow keys!"
	elif current_state == MinigameState.PLAYING:
		combo_label.text = "Items left: %d" % (total_items - current_item_index)
