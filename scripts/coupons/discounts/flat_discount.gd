class_name FlatDiscount
extends Discount

@export var amount: float

func apply(filtered_cart: Dictionary) -> float:
	var total_items = 0
	for count in filtered_cart.values():
		total_items += count
	return amount * total_items

func describe() -> String:
	return "-%.2fg each" % amount
