class_name Order
extends Resource

enum Difficulty { EASY, MEDIUM, HARD }

@export var id: String
@export var title: String
@export var difficulty: Difficulty
@export var line_items: Dictionary[Ingredient, int]


func raw_cost() -> int:
	var total = 0
	for ing in line_items:
		total += ing.price * line_items[ing]
	return total

func reward() -> int:
	return int(floor(raw_cost() * GameState.REWARD_MULTIPLIER))

# Returns false if the order cannot be fulfilled (missing items).
# On success, mutates GameState.pending_order_rewards and returns true.
func try_fulfill(successful_items: Array, damaged_items: Array) -> bool:
	var all_items = successful_items + damaged_items

	for ing in line_items:
		var needed = line_items[ing]
		var found = all_items.filter(func(i): return (i == ing)).size()
		if found < needed:
			return false

	var base = reward()
	var damaged_count = 0

	for ing in line_items:
		var needed = line_items[ing]
		var in_damaged = damaged_items.filter(func(i): return i == ing).size()
		damaged_count += mini(in_damaged, needed)

	var penalty = int(floor(base * 0.1 * damaged_count))
	var earned = base - penalty
	
	GameState.pending_order_rewards.append({
		"title": title,
		"earned": earned,
		"penalty": penalty,
		"damaged_count": damaged_count,
	})

	return true
