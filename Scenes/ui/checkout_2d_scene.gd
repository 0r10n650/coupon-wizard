extends Node2D

@onready var anim_player = $AnimationPlayer
@onready var receipt_scn = $ReceiptScene

func _ready():
	receipt_scn.visible = false
	await get_tree().create_timer(0.5).timeout
	
	anim_player.play("Checkout")
	await anim_player.animation_finished
	
	receipt_scn.visible = true
	
	var original_y = receipt_scn.position.y  # store where it should end up
	receipt_scn.position.y = original_y + 200  # start below
	receipt_scn.visible = true

	var tween = create_tween()
	tween.tween_property(receipt_scn, "position:y", original_y, 0.5)\
		.set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	
	receipt_scn.setup(GameState.successful_items, GameState.destroyed_items)
