extends Node

# OrderGenerator — autoload this as "OrderGenerator"
# Generates a pool of orders for the day based on shelf categories.
# Each order has a size class (small/medium/large) which determines
# how many categories and items it draws from.

# size class weights — large orders are rarer
const SIZE_WEIGHTS = {
	"small":  50,
	"medium": 35,
	"large":  15,
}

# item count range per size class: [unique_ingredients_min, max, qty_min, qty_max]
const SIZE_CONFIG = {
	"small":  {"ingredients": [2, 3],  "qty": [1, 4],  "categories": 1},
	"medium": {"ingredients": [4, 6],  "qty": [2, 6],  "categories": 2},
	"large":  {"ingredients": [7, 12], "qty": [3, 8],  "categories": 3},
}

# reward markup range — order pays slightly more than raw item cost
const REWARD_MARKUP_MIN = 1.1
const REWARD_MARKUP_MAX = 1.25


func generate_pool(pool_size: int) -> Array:
	var orders = []
	for i in range(pool_size):
		orders.append(_generate_order())
	return orders


func _generate_order() -> Dictionary:
	var size_class = _pick_size_class()
	var cfg = SIZE_CONFIG[size_class]

	var categories = ShelfRegistry.get_categories().duplicate()
	categories.shuffle()
	var chosen_categories = categories.slice(0, cfg["categories"])

	# gather items from the chosen categories
	var ingredient_count = randi_range(cfg["ingredients"][0], cfg["ingredients"][1])
	var per_category = ceili(float(ingredient_count) / chosen_categories.size())

	var all_items: Array = []
	for cat in chosen_categories:
		var items = ShelfRegistry.get_random_items_from_category(cat, per_category)
		all_items.append_array(items)

	# trim to target count and assign quantities
	all_items.shuffle()
	all_items = all_items.slice(0, ingredient_count)

	var line_items: Array = []
	var raw_cost: float = 0.0
	for item in all_items:
		var qty = randi_range(cfg["qty"][0], cfg["qty"][1])
		raw_cost += item["price"] * qty
		line_items.append({
			"name":     item["name"],
			"price":    item["price"],
			"quantity": qty,
		})

	var markup  = randf_range(REWARD_MARKUP_MIN, REWARD_MARKUP_MAX)
	var reward  = int(round(raw_cost * markup))

	return {
		"size":       size_class,
		"line_items": line_items,
		"raw_cost":   int(round(raw_cost)),
		"reward":     reward,
		"categories": chosen_categories,  # kept so UI can show a location hint
	}


func _pick_size_class() -> String:
	var total = 0
	for w in SIZE_WEIGHTS.values():
		total += w

	var roll = randi() % total
	var cumulative = 0
	for size_class in SIZE_WEIGHTS:
		cumulative += SIZE_WEIGHTS[size_class]
		if roll < cumulative:
			return size_class

	return "small"  # fallback, should never hit
