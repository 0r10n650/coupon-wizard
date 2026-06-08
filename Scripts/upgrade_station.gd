extends StaticBody3D

var outline_material: ShaderMaterial
var upgrade_ui_scene = preload("res://Scenes/Management/upgrade_ui.tscn")
var active_ui = null
@onready var mesh_instance = $MeshInstance3D

func _ready():
	var shader = load("res://outline.gdshader")
	if shader:
		outline_material = ShaderMaterial.new()
		outline_material.shader = shader
		outline_material.set_shader_parameter("outline_width", 0.05)
		outline_material.set_shader_parameter("outline_color", Color(0.0, 1.0, 0.5, 1.0))

func interact():
	if active_ui == null:
		active_ui = upgrade_ui_scene.instantiate()
		get_tree().current_scene.add_child(active_ui)
		active_ui.tree_exited.connect(func(): active_ui = null)
		
		# Lock player movement
		var player = get_tree().current_scene.get_node_or_null("Player")
		if player and player.has_method("set_movement_locked"):
			player.set_movement_locked(true)
			active_ui.tree_exited.connect(func(): player.set_movement_locked(false))

func focus():
	if mesh_instance and outline_material:
		mesh_instance.material_overlay = outline_material

func unfocus():
	if mesh_instance:
		mesh_instance.material_overlay = null
