extends VBoxContainer
class_name inventory

const ITEM_SCENE = preload("res://Scenes/ui/inventory_item.tscn")

var _inventory : Array[inventory_item_2D]

func add_item(_ingredient: Ingredient):
	for current_item in _inventory:
		if current_item.ingredient == _ingredient:
			current_item.increase_count()
			return
	
	var new_inv_item: inventory_item_2D = ITEM_SCENE.instantiate()
	new_inv_item.ingredient = _ingredient
	_inventory.append(new_inv_item)
	add_child(new_inv_item)
	new_inv_item.increase_count()
