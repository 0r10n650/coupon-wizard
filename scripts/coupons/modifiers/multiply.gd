class_name MultiplyCoupon
extends Resource

@export var multiplier: float

func apply(prev_result: CouponResult) -> float:
	if prev_result.conditions_still_valid:
		return prev_result.discount_total * multiplier
	return 0.0
