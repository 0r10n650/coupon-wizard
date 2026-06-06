extends CouponEffect
class_name StaticOffEffect

@export var amount: float

func apply(successful: Array, 
	destroyed: Array, 
	total: int, 
	equipped_ids: Array = [], 
	current_slot: int = 0) -> int:
	return amount
