class_name PotionRecipe
extends Resource

@export var potion_name: String
@export var sell_price: float
@export var ingredients_required: Array[Ingredient]
@export var counts_required: Array[int]

# Helper to check if a dictionary of {ingredient_name: count} satisfies this recipe
func can_craft(inventory: Dictionary) -> bool:
	for i in range(ingredients_required.size()):
		var ing = ingredients_required[i]
		var req_count = counts_required[i]
		if not inventory.has(ing.name) or inventory[ing.name] < req_count:
			return false
	return true
