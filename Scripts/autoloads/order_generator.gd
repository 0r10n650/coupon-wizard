extends Node

# OrderGenerator — autoload
# Produces Order resources procedurally from ShelfRegistry data.
# OrderManager calls generate_pool() for the daily pool;
# nothing else should need to touch this directly.

const SIZE_WEIGHTS = {
	"small":  50,
	"medium": 35,
	"large":  15,
}

const SIZE_CONFIG = {
	"small":  {"ingredients": [2, 3],  "qty": [1, 4],  "categories": 1},
	"medium": {"ingredients": [4, 6],  "qty": [2, 6],  "categories": 2},
	"large":  {"ingredients": [7, 12], "qty": [3, 8],  "categories": 3},
}

const SIZE_DIFFICULTY = {
	"small":  Order.Difficulty.EASY,
	"medium": Order.Difficulty.MEDIUM,
	"large":  Order.Difficulty.HARD,
}


func generate_pool(pool_size: int) -> Array[Order]:
	var orders: Array[Order] = []
	for i in pool_size:
		orders.append(_generate_order())
	return orders


func _generate_order() -> Order:
	var size_class  = _pick_size_class()
	var cfg         = SIZE_CONFIG[size_class]

	var categories = ShelfRegistry.get_categories().duplicate()
	categories.shuffle()
	var chosen_categories = categories.slice(0, cfg["categories"])

	var ingredient_count = randi_range(cfg["ingredients"][0], cfg["ingredients"][1])
	var per_category     = ceili(float(ingredient_count) / max(1, chosen_categories.size()))

	var all_ingredients: Array = []
	for cat in chosen_categories:
		var items = ShelfRegistry.get_random_items_from_category(cat, per_category)
		all_ingredients.append_array(items)

	all_ingredients.shuffle()
	all_ingredients = all_ingredients.slice(0, ingredient_count)

	var line_items: Dictionary[Ingredient, int] = {}
	for ingredient in all_ingredients:
		line_items[ingredient] = randi_range(cfg["qty"][0], cfg["qty"][1])

	var order        = Order.new()
	order.title      = _make_title(size_class, chosen_categories)
	order.difficulty = SIZE_DIFFICULTY[size_class]
	order.line_items = line_items

	return order


func _make_title(size_class: String, categories: Array) -> String:
	# e.g. "Small Herbalism Order", "Large Fire & Water Order"
	var cat_str = " & ".join(categories.map(func(c): return c.capitalize()))
	return "%s %s Order" % [size_class.capitalize(), cat_str]


func _pick_size_class() -> String:
	var total = 0
	for w in SIZE_WEIGHTS.values():
		total += w

	var roll       = randi() % total
	var cumulative = 0
	for size_class in SIZE_WEIGHTS:
		cumulative += SIZE_WEIGHTS[size_class]
		if roll < cumulative:
			return size_class

	return "small"
