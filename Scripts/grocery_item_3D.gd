extends Node3D
class_name grocery_Item_3D

@export var item : Ingredient
@onready var sprite3D = $Sprite3D

func _ready():
	sprite3D.texture = item.image
