extends PanelContainer
class_name OrderRewardOverlay

signal dismissed

@onready var order_list = %OrderList
@onready var reward_label = %RewardLabel
@onready var rebate_label = %RebateLabel
@onready var total_label = %TotalLabel
@onready var confirm_btn = %ConfirmButton

func _ready() -> void:
	OrderManager.fulfill_active_orders(GameState.successful_items, GameState.destroyed_items)
	setup(GameState.pending_order_rewards, GameState.REBATE_FRACTION)
	
func setup(order_results: Array, rebate: int) -> void:
	if not is_node_ready():
		await ready

	var grand_total = 0
	for result in order_results:
		var row = Label.new()
		var text = result["title"] + ":  +" + str(result["earned"]) + "g"
		if result["damaged_count"] > 0:
			text += "  (-%dg damage penalty)" % result["penalty"]
		row.text = text
		order_list.add_child(row)
		grand_total += result["earned"]

	rebate_label.text = "Unused items sold back: +%dg" % rebate
	grand_total += rebate
	total_label.text = "Total earned: +%dg" % grand_total
	GameState.add_gold(grand_total)

func _on_confirm() -> void:
	SceneLoader.load_scene("res://Scenes/Management/management_screen.tscn")

func _check_orders() -> void:
	GameState.pending_order_rewards = []
	GameState.pending_rebate = 0
	OrderManager.fulfill_active_orders(GameState.successful_items, GameState.destroyed_items)
