extends Control
class_name receipt_item

@export var item : Ingredient
@export var count : int = 1
@onready var count_label = $HBoxContainer/MarginContainer/ItemCount
@onready var name_label = $HBoxContainer/ItemName
@onready var price_label = $HBoxContainer/MarginContainer2/ItemPrice

@export var destroyed: bool = false

func _update_ui():
	count_label.text = str(count)
	name_label.text = item.name
	price_label.text = str(item.price * count) +".00"
	if destroyed:
		name_label.text += " (Destroyed)"
		count_label.add_theme_color_override("font_color", Color.RED)
		name_label.add_theme_color_override("font_color", Color.RED)
		price_label.add_theme_color_override("font_color", Color.RED)

func setup(_item, _count, _destroyed = false):
	item = _item
	count = _count
	destroyed = _destroyed
	await ready
	_update_ui()
