extends Control

var cart: Dictionary = {}  # Ingredient -> quantity
var selected_coupons: Array[Coupon] = []
var all_ingredients: Array[Ingredient] = []
var all_coupons: Array[Coupon] = []

var tile_scene = preload("res://scenes/ui/ItemTile.tscn")

# UI references - assign these in the editor
@onready var items_container = $VBoxContainer/ItemsRow
@onready var coupons_container = $VBoxContainer/CouponsRow
@onready var result_label = $VBoxContainer/ResultLabel

func _ready() -> void:
	_setup_ingredients()
	_setup_coupons()
	_build_item_buttons()
	_build_coupon_buttons()

func _setup_ingredients() -> void:
	all_ingredients = [
		preload("res://data/ingredients/dragon_scale.tres"),
		preload("res://data/ingredients/human_dust.tres"),
		preload("res://data/ingredients/unicorn_hair.tres"),
		preload("res://data/ingredients/whos_in_whoville.tres"),
	]

func _setup_coupons() -> void:
	var flat = FlatDiscount.new()
	flat.amount = 2.0

	var coupon_a = Coupon.new()
	coupon_a.discount = flat

	var flat2 = FlatDiscount.new()
	flat2.amount = 5.0

	var coupon_b = Coupon.new()
	coupon_b.discount = flat2

	all_coupons = [coupon_a, coupon_b]

func _build_item_buttons() -> void:
	for ingredient in all_ingredients:
		var tile = tile_scene.instantiate()
		tile.ingredient = ingredient
		tile.quantity_changed.connect(_on_quantity_changed)
		items_container.add_child(tile)
		
func _on_quantity_changed(ingredient: Ingredient, delta: int) -> void:
	if delta > 0:
		cart[ingredient] = cart.get(ingredient, 0) + delta
	else:
		var new_count = cart.get(ingredient, 0) + delta
		if new_count <= 0:
			cart.erase(ingredient)
		else:
			cart[ingredient] = new_count

func _build_coupon_buttons() -> void:
	for i in all_coupons.size():
		var coupon = all_coupons[i]
		var btn = Button.new()
		btn.text = "Coupon %d (-%.2fg each)" % [i + 1, coupon.discount.amount]
		btn.pressed.connect(_on_coupon_clicked.bind(coupon, btn))
		coupons_container.add_child(btn)

func _on_coupon_clicked(coupon: Coupon, btn: Button) -> void:
	selected_coupons.append(coupon)
	btn.disabled = true

func _on_apply_pressed() -> void:
	if cart.is_empty():
		result_label.text = "No items in cart."
		return

	var cart_total = 0
	for ingredient in cart:
		cart_total += ingredient.price * cart[ingredient]
	var total_discount = 0.0

	for coupon in selected_coupons:
		total_discount += coupon.quick_apply(cart)

	var final_total = max(cart_total - total_discount, 0.0)
	result_label.text = "Cart: %.2fg | Discount: %.2fg | Total: %.2fg" % [cart_total, total_discount, final_total]

func _on_reset_pressed() -> void:
	cart.clear()
	selected_coupons.clear()
	result_label.text = ""

	for item in items_container.get_children():
		item.set_quantity(0)

	for btn in coupons_container.get_children():
		btn.disabled = false
