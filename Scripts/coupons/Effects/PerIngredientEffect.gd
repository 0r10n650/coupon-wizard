extends CouponEffect
class_name PerIngredientEffect

@export var item: Ingredient
@export var amount: float
@export var invincible: bool 

func apply(successful: Array, 
	destroyed: Array, 
	total: int, 
	equipped_ids: Array = [], 
	current_slot: int = 0) -> int:
	var disc_total = 0
	for _item in successful:
		if _item == item:
			disc_total += amount
	
	for _item in destroyed.duplicate():
		if _item == item:
			disc_total += amount
		if invincible:
			successful.append(_item)
			destroyed.erase(_item)
	
	return disc_total
