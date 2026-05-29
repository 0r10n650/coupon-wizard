class_name PercentageDiscount
extends Discount

@export var percentage: float  # 0.25 = 25%

func apply(cart: Dictionary) -> float:
	var total = 0
	for item in cart:
		total += item.price * cart[item]
	return total * percentage

func describe() -> String:
	return "%d%% off" % [percentage * 100]
