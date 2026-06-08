extends Control

@onready var anim_player = $AnimationPlayer
@onready var receipt_scn = $ReceiptScene
@onready var coupon_apply = $CouponApplyScene

func _on_coupon_apply_scene_is_done():
	print("coupons finished")
	coupon_apply.visible = false
	await get_tree().create_timer(0.5).timeout
	anim_player.play("Checkout")
	await anim_player.animation_finished
	
	receipt_scn.visible = true
	var original_y = receipt_scn.position.y
	receipt_scn.position.y = original_y + 200
	var tween = create_tween()
	tween.tween_property(receipt_scn, "position:y", original_y, 0.5).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	receipt_scn.setup(GameState.successful_items, GameState.destroyed_items)
