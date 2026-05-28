extends StaticBody3D

signal interacted

@onready var mesh_instance = $MeshInstance3D
var outline_material: ShaderMaterial

func _ready():
	var shader = load("res://outline.gdshader")
	if shader:
		outline_material = ShaderMaterial.new()
		outline_material.shader = shader
		outline_material.set_shader_parameter("outline_width", 0.02)
		outline_material.set_shader_parameter("outline_color", Color(1.0, 1.0, 0.0, 1.0))

func interact():
	print("Coupon book interacted!")
	interacted.emit()

func focus():
	if mesh_instance and outline_material:
		mesh_instance.material_overlay = outline_material

func unfocus():
	if mesh_instance:
		mesh_instance.material_overlay = null
