extends Node

# ShelfRegistry — autoload this as "ShelfRegistry"
# Populate _shelf_data with your actual ingredients once your store is built out.
# Keys are category names, values are arrays of Ingredient resource paths.
# Ingredients can appear in multiple categories if they live on a crossover shelf.

# Each entry: { "path": "res://...", "name": "...", "price": N }
# We store dicts rather than loaded resources so this file stays readable
# and doesn't force-load every texture at boot.

var _shelves: Dictionary = {
	"produce": [
		{"name": "Apple",      "price": 2},
		{"name": "Carrot",     "price": 1},
		{"name": "Onion",      "price": 1},
		{"name": "Tomato",     "price": 2},
		{"name": "Lettuce",    "price": 2},
		{"name": "Potato",     "price": 1},
		{"name": "Garlic",     "price": 1},
		{"name": "Mushroom",   "price": 3},
	],
	"dairy": [
		{"name": "Milk",       "price": 3},
		{"name": "Butter",     "price": 4},
		{"name": "Eggs",       "price": 5},
		{"name": "Cheese",     "price": 6},
		{"name": "Yogurt",     "price": 4},
		{"name": "Cream",      "price": 5},
	],
	"bakery": [
		{"name": "Bread",      "price": 4},
		{"name": "Flour",      "price": 2},
		{"name": "Sugar",      "price": 2},
		{"name": "Yeast",      "price": 3},
		{"name": "Oats",       "price": 3},
	],
	"pantry": [
		{"name": "Rice",       "price": 3},
		{"name": "Pasta",      "price": 3},
		{"name": "Olive Oil",  "price": 6},
		{"name": "Vinegar",    "price": 4},
		{"name": "Salt",       "price": 1},
		{"name": "Pepper",     "price": 2},
		{"name": "Canned Tomatoes", "price": 3},
	],
	"drinks": [
		{"name": "Juice",      "price": 4},
		{"name": "Soda",       "price": 3},
		{"name": "Water",      "price": 2},
		{"name": "Coffee",     "price": 7},
		{"name": "Tea",        "price": 5},
	],
	"frozen": [
		{"name": "Ice Cream",  "price": 6},
		{"name": "Frozen Peas","price": 4},
		{"name": "Fish Fillet","price": 8},
		{"name": "Pizza",      "price": 9},
	],
}


func get_categories() -> Array:
	return _shelves.keys()


func get_items_in_category(category: String) -> Array:
	return _shelves.get(category, [])


func get_random_items_from_category(category: String, count: int) -> Array:
	var pool = _shelves.get(category, []).duplicate()
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))
