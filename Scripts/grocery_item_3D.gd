extends Node3D
class_name grocery_Item_3D

@export var item : ItemData
@onready var sprite3D = $Sprite3D

func _ready():
	print("Sprite node: ", sprite3D)
	print("Children: ", get_children())
	sprite3D.texture = item.sprite
