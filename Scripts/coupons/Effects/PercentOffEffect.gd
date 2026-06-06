extends CouponEffect
class_name PercentOffEffect

@export var percent: float

func apply(successful: Array, 
	destroyed: Array, 
	total: int, 
	equipped_ids: Array = [], 
	current_slot: int = 0) -> int:
	return int(total * (percent / 100.0))
