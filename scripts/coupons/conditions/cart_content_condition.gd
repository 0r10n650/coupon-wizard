class_name CartContentCondition
extends Condition

enum Mode { MUST_HAVE, MUST_AVOID }

@export var mode: Mode
@export var strict_items: Array[ItemQuantity]

func evaluate(cart: Array, applied_coupons: Array) -> bool:
	match mode:
		Mode.MUST_AVOID:
			return not cart.any(func(item): return item in strict_items)
		Mode.MUST_HAVE:
			for si in strict_items:
				var count = 0
				for item in cart:
					if item == si.item:
						count += 1
				if count < si.quantity:
					return false
			return true
	return false
