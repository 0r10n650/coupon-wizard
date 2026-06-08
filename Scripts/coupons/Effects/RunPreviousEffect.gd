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
	var prev_coupon = _find_coupon(prev_id)
	if prev_coupon == null:
		return total
	var discount = 0
	for i in range(amount):
		discount += prev_coupon.apply(successful, destroyed, total, equipped_ids, prev_slot)
	return discount

func _find_coupon(id: String):
	var db = load("res://data/coupons/CouponDatabase.tres")
	for coupon in db.coupons:
		if coupon.id == id:
			return coupon
	return null
