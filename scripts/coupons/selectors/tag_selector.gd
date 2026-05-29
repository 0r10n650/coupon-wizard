class_name TagSelector
extends Selector

@export var target: String

# Select items based on their tags.
func select(cart: Dictionary) -> Dictionary:
	var filt_cart = Dictionary()
	for key in cart:
		if target in key.tags:
			filt_cart[key] = cart[key]
	return filt_cart
