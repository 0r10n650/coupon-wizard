extends StaticBody3D

var outline_material: ShaderMaterial
@onready var mesh_instance = $MeshInstance3D

func _ready():
	var shader = load("res://outline.gdshader")
	if shader:
		outline_material = ShaderMaterial.new()
		outline_material.shader = shader
		outline_material.set_shader_parameter("outline_width", 0.05)
		outline_material.set_shader_parameter("outline_color", Color(1.0, 0.5, 0.0, 1.0))

func interact():
	print("Shopping door interacted! Going to store...")
	# Unlock player movement before transitioning in case it persists
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(false)
		
	SceneLoader.load_scene("res://Scenes/Shopping/shopping.tscn")

func focus():
	if mesh_instance and outline_material:
		mesh_instance.material_overlay = outline_material

func unfocus():
	if mesh_instance:
		mesh_instance.material_overlay = null
