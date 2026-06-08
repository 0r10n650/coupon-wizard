extends CanvasLayer
class_name ShoppingTimerUI

var time_left: float = 0.0
var max_time: float = 1.0

var panel: PanelContainer
var time_label: Label
var progress_bar: ProgressBar
var is_pulsing: bool = false
var pulse_tween: Tween

signal timer_finished

func _init(initial_time: float = 30.0):
	time_left = initial_time
	max_time = initial_time
	
func _ready():
	# Build the professional UI dynamically
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_top", 500)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	
	var center_container = CenterContainer.new()
	
	panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.2, 0.7, 1.0, 1.0)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 15
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	
	var title_label = Label.new()
	title_label.text = "Shopping Time Remaining"
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	time_label = Label.new()
	time_label.add_theme_font_size_override("font_size", 32)
	time_label.add_theme_color_override("font_color", Color(1, 1, 1))
	time_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	time_label.add_theme_constant_override("outline_size", 4)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(350, 18)
	progress_bar.show_percentage = false
	progress_bar.max_value = max_time
	progress_bar.value = time_left
	
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.2, 0.2, 0.2)
	p_style.corner_radius_top_left = 9
	p_style.corner_radius_top_right = 9
	p_style.corner_radius_bottom_left = 9
	p_style.corner_radius_bottom_right = 9
	progress_bar.add_theme_stylebox_override("background", p_style)
	
	var f_style = StyleBoxFlat.new()
	f_style.bg_color = Color(0.2, 0.7, 1.0)
	f_style.corner_radius_top_left = 9
	f_style.corner_radius_top_right = 9
	f_style.corner_radius_bottom_left = 9
	f_style.corner_radius_bottom_right = 9
	progress_bar.add_theme_stylebox_override("fill", f_style)
	
	#vbox.add_child(title_label)
	vbox.add_child(time_label)
	#vbox.add_child(progress_bar)
	
	panel.add_child(vbox)
	center_container.add_child(panel)
	margin.add_child(center_container)
	add_child(margin)
	
	update_display()
	
	_set_all_mouse_ignore(self)
	# Wait one frame before setting pivot so size is calculated
	await get_tree().process_frame
	panel.pivot_offset = panel.size / 2

func _set_all_mouse_ignore(node: Node):
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_all_mouse_ignore(child)

func _process(delta):
	if time_left > 0:
		time_left -= delta
		if time_left <= 0:
			time_left = 0
			timer_finished.emit()
			set_process(false)
			
		update_display()
		check_pulse()

func update_display():
	var mins = int(time_left) / 60
	var secs = int(time_left) % 60
	var millis = int((time_left - int(time_left)) * 100)
	time_label.text = "%02d:%02d.%02d" % [mins, secs, millis]
	progress_bar.value = time_left
	
	if time_left <= 10.0 and not is_pulsing:
		var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
		style.border_color = Color(1.0, 0.3, 0.3)
		
		var f_style = progress_bar.get_theme_stylebox("fill") as StyleBoxFlat
		f_style.bg_color = Color(1.0, 0.3, 0.3)
		
		time_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

func check_pulse():
	if time_left <= 10.0 and time_left > 0:
		if not is_pulsing:
			start_pulse()

func start_pulse():
	is_pulsing = true
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(panel, "scale", Vector2(1.03, 1.03), 0.5).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE)
