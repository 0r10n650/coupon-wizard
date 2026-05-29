class_name CartValueCondition
extends Condition

enum Mode { MIN, MAX }

@export var mode: Mode
@export var value: float

func evaluate(cart: Array, applied_coupons: Array) -> bool:
	var total = 0.0
	for item in cart:
		total += item.price
	match mode:
		Mode.MIN: return total >= value
		Mode.MAX: return total <= value
	return false
