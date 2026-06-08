extends CouponEffect
class_name PerIngredientEffect

@export var items: Array[Ingredient]
@export var amount: float
@export var percent: bool
@export var invincible: bool 

func apply(successful: Array, 
	destroyed: Array, 
	total: int, 
	equipped_ids: Array = [], 
	current_slot: int = 0) -> int:
	var disc_total = 0
	for _item in successful:
		if items.has(_item):
			if percent: 
				disc_total += _item.price * (amount/100)
			else:
				disc_total += amount
	
	for _item in destroyed.duplicate():
		if items.has(_item):
			if percent: 
				disc_total += _item.price * (amount/100)
			else:
				disc_total += amount
		if invincible:
			successful.append(_item)
			destroyed.erase(_item)
	return disc_total
