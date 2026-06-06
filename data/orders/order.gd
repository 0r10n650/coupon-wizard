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
