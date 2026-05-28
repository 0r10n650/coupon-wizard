class_name Coupon
extends Resource

@export var gates: Array[Condition]
# @export var target: TargetSelector
@export var discount: Discount

func quick_apply(cart: Dictionary) -> float:
	return discount.apply(cart)
	
func apply(cart: Array, applied_coupons: Array) -> CouponResult:
	var result = CouponResult.new()
	
	# Check expiration and gates
	for gate in gates:
		if not gate.evaluate(cart, applied_coupons):
			result.was_success = false
			result.remaining_items = cart
			return result
	
	# Get target items
	# var targeted = target.select(cart)
	
	# Apply discount
	# result.applied_items = targeted
	# result.discount_total = discount.apply(targeted)
	# result.remaining_items = cart.filter(func(item): return item not in targeted)
	result.was_success = true
	
	# Re-evaluate gates against remaining items for MultiplyCoupon
	result.conditions_still_valid = gates.all(func(g): 
		return g.evaluate(result.remaining_items, applied_coupons))
	
	return result
