extends SceneTree

func _init():
	var theme = Theme.new()
	var font = load("res://Assets/Fonts/LilitaOne-Regular.ttf")
	theme.default_font = font
	theme.default_font_size = 24
	
	# Panel Style
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.12, 0.25, 0.95) # Dark Purple
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.3, 0.2, 0.5, 1.0)
	panel_style.shadow_color = Color(0, 0, 0, 0.4)
	panel_style.shadow_size = 6
	theme.set_stylebox("panel", "Panel", panel_style)
	theme.set_stylebox("panel", "PanelContainer", panel_style)
	
	# Button Styles
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.95, 0.75, 0.1, 1.0) # Gold
	btn_normal.corner_radius_top_left = 8
	btn_normal.corner_radius_top_right = 8
	btn_normal.corner_radius_bottom_left = 8
	btn_normal.corner_radius_bottom_right = 8
	btn_normal.border_width_bottom = 6
	btn_normal.border_color = Color(0.7, 0.5, 0.0, 1.0)
	btn_normal.content_margin_left = 16
	btn_normal.content_margin_right = 16
	btn_normal.content_margin_top = 8
	btn_normal.content_margin_bottom = 8
	
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = Color(1.0, 0.85, 0.3, 1.0)
	
	var btn_pressed = btn_normal.duplicate()
	btn_pressed.bg_color = Color(0.8, 0.6, 0.0, 1.0)
	btn_pressed.border_width_bottom = 0
	btn_pressed.content_margin_top = 14
	btn_pressed.content_margin_bottom = 2
	
	var btn_disabled = btn_normal.duplicate()
	btn_disabled.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	btn_disabled.border_color = Color(0.2, 0.2, 0.2, 1.0)
	
	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	
	theme.set_color("font_color", "Button", Color(0.1, 0.1, 0.1, 1.0))
	theme.set_color("font_hover_color", "Button", Color(0.05, 0.05, 0.05, 1.0))
	theme.set_color("font_focus_color", "Button", Color(0.1, 0.1, 0.1, 1.0))
	theme.set_color("font_pressed_color", "Button", Color(0.1, 0.1, 0.1, 1.0))
	theme.set_color("font_disabled_color", "Button", Color(0.6, 0.6, 0.6, 1.0))
	
	# HSeparator
	var sep = StyleBoxLine.new()
	sep.color = Color(0.5, 0.4, 0.7, 0.5)
	sep.thickness = 2
	theme.set_stylebox("separator", "HSeparator", sep)
	
	ResourceSaver.save(theme, "res://main_theme.tres")
	print("Theme generated and saved to res://main_theme.tres")
	quit()
