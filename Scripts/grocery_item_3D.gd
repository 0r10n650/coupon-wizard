@tool
extends Node3D
class_name grocery_Item_3D

@export var item : Ingredient :
	set(value):
		item = value
		_update_ui()
@export var image_scale : float = 1.0 :
	set(value):
		image_scale = value
		_update_ui()
@export var shelf_count : int :
	set(value):
		shelf_count = value
		_update_ui()
@onready var sprite3D = $Sprite3D
@onready var name_label = $Name
@onready var cost_label = $Cost
@onready var area = $Area3D

func _ready():
	_update_ui()

func _update_ui():
	if sprite3D == null:
		sprite3D = get_node_or_null("Sprite3D")
	if name_label == null:
		name_label = get_node_or_null("Name")
	if cost_label == null:
		cost_label = get_node_or_null("Cost")
	if sprite3D and item:
		sprite3D.texture = item.image
		sprite3D.pixel_size = 0.01 * image_scale
	if name_label and item:
		name_label.text = item.name + " x" + str(shelf_count)
	if cost_label and item:
		cost_label.text = str(item.price) + "G"

func _get_item():
	if shelf_count > 0:
		shelf_count -= 1
		_update_ui()
	if shelf_count == 0:
		sprite3D.modulate = Color(0.545, 0.545, 0.545, 0.506)
