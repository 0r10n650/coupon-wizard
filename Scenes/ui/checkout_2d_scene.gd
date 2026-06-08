extends Control

@onready var anim_player = $AnimationPlayer
@onready var receipt_scn = $ReceiptScene
@onready var coupon_apply = $CouponApplyScene

var total
var successful_items
var destroyed_items
var discount = 0
var current_discount = 0

@onready var coupon_list = $CouponApplyScene/PanelContainer/VBoxContainer/CouponList
@onready var disLabel = $CouponApplyScene/PanelContainer/VBoxContainer/VBoxContainer2/DiscountLabel
@onready var tlabel = $CouponApplyScene/PanelContainer/VBoxContainer/VBoxContainer2/TotalLabel
@onready var button = $CouponApplyScene/PanelContainer/VBoxContainer/VBoxContainer2/Button

func _ready():
	successful_items = GameState.successful_items
	destroyed_items = GameState.destroyed_items
	button.visible = false
	start()

func start():
	print("start called")
	if not is_node_ready():
		await ready
	self.visible = true
	load_total()
	_build_coupon_cards()
	_apply_coupons()

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
	tlabel.text += " TOTAL: " + str(total) + ".00"
	disLabel.text = "DISCOUNT: 0.00"

func _build_coupon_cards():
	print("equipped_coupon_ids: ", GameState.equipped_coupon_ids)
	for id in GameState.equipped_coupon_ids:
		if id == null or id == "":
			continue
		var card = preload("res://Scenes/ui/Coupon.tscn").instantiate()
		var data = _find_coupon_data(str(id))
		print("id: ", id, " | data: ", data)
		card.data = data
		coupon_list.add_child(card)
		print("card added: ", card)

func _apply_coupons():
	var current_slot = 0
	var starting_total = total
	var has_valid_coupon = false
	for card in coupon_list.get_children():
		if card.data == null:
			current_slot += 1
			continue
		has_valid_coupon = true
		await get_tree().create_timer(1.0).timeout
		current_discount = card.data.apply(successful_items, destroyed_items, starting_total, GameState.equipped_coupon_ids, current_slot)
		discount += current_discount
		starting_total -= current_discount
		current_slot += 1
		_animate_card(card)
		update_ui()
	GameState.discount = discount
		
	button.visible = true

func _animate_card(card: Control):
	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2(1.15, 1.15), 0.1).set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)

func update_ui():
	tlabel.text = "TOTAL: " + str(total - discount) + ".00"
	disLabel.text += "\n-" + str(current_discount) + ".00"

func _find_coupon_data(id: String):
	for coupon in GameState.COUPON_DB.coupons:
		if coupon.id == id:
			return coupon
	return null

func _on_coupon_apply_scene_is_done():
	print("coupons finished")
	coupon_apply.visible = false
	anim_player.play("Checkout")
	await anim_player.animation_finished
	
	receipt_scn.visible = true
	var original_y = receipt_scn.position.y
	receipt_scn.position.y = original_y + 200
	var tween = create_tween()
	tween.tween_property(receipt_scn, "position:y", original_y, 0.5).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	receipt_scn.setup(GameState.successful_items, GameState.destroyed_items)
