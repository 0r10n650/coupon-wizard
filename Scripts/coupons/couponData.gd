class_name CouponData
extends Resource

@export var name: String
@export var description: String
@export var effect: CouponEffect

func apply(successful: Array, 
	destroyed: Array, 
	total: int, 
	equipped_ids: Array = [], 
	current_slot: int = 0) -> int:
	return effect.apply(successful, destroyed, total, equipped_ids, current_slot)
