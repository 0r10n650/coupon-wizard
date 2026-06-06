extends Control
class_name CouponApplyScene

var total
var successful_items
var destroyed_items
var current_coupon
var discount = 0
var current_discount = 0

const receipt_scene = preload("res://Scenes/ui/Checkout2dScene.tscn")

@onready var slabel = $SuccessLabel
@onready var dlabel = $DestroyedLabel
@onready var disLabel = $DiscountLabel
@onready var tlabel = $TotalLabel
@onready var couponsArray = $Coupons

func _ready():
	successful_items = GameState.successful_items
	destroyed_items = GameState.destroyed_items
	load_total()

func load_total():
	var successful_total = 0
	for item in successful_items:
		if item != null:
			var val = item.get("price")
			if val != null:
				successful_total += int(round(val))
			
	var destroyed_total = 0
	for item in destroyed_items:
		if item != null:
			var val = item.get("price")
			if val != null:
				destroyed_total += int(round(val))
	
	total = successful_total + destroyed_total
	
	slabel.text += " " + str(successful_total) + ".00"
	dlabel.text += " " + str(destroyed_total) + ".00"
	tlabel.text += " " + str(total) + ".00"
	disLabel.text += " 0.00"

func  _apply_coupons():
	var current_slot = 0
	for coupon in couponsArray.get_children():
		current_discount = coupon.data.apply(successful_items, destroyed_items, total, couponsArray.get_children(), current_slot)
		current_slot += 1
		discount += current_discount
		update_ui()
		await get_tree().create_timer(1).timeout
	GameState.discount = discount
	get_tree().change_scene_to_packed(receipt_scene)

func update_ui():
	tlabel.text = "TOTAL: " + str(total - discount) + ".00"
	disLabel.text += "\nDISCOUNT: -" + str(current_discount) + ".00"
