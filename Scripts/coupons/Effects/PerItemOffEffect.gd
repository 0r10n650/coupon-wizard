extends CouponEffect
class_name PerItemOffEffect

@export var amount: float

enum cart_type {
	ALL,
	SUCCESS,
	DESTROY
}
@export var type: cart_type

func apply(successful: Array, 
	destroyed: Array, 
	total: int, 
	equipped_ids: Array = [], 
	current_slot: int = 0) -> int:
	var total_discount = 0
	if type != cart_type.DESTROY:
		for item in successful:
			total_discount += amount
	if type != cart_type.SUCCESS:
		for item in destroyed:
			total_discount += amount
	return total_discount
