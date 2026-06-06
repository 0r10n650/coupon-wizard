extends CouponEffect
class_name RunPreviousEffect

@export var amount: float

func apply(successful: Array, 
	destroyed: Array, 
	total: int, 
	equipped_ids: Array = [], 
	current_slot: int = 0) -> int:
	var prev_slot = current_slot - 1
	if prev_slot < 0:
		return total
	var prev_id = equipped_ids[prev_slot]
	return prev_id.data.apply(successful,destroyed,total,equipped_ids,current_slot)
