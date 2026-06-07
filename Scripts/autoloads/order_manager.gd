extends Node

const REWARD_MULT = [1.15, 1.15, 1.25, 1.25, 1.5]
const POOL_SIZE = 5
const INCOMPLETE_REBATE = 0.5


# Called by GameState.begin_day() — generates and caches the daily pool exactly once.
func generate_order_pool() -> Array[Order]:
	# Day specific pools.
	if GameState.current_day == 1:
		var order1 := load("res://data/orders/easy_orders/tutorial_frog.tres")
		return [order1]
	elif GameState.current_day == 2:
		var order1 := load("res://data/orders/easy_orders/tutorial_eyes.tres")
		var order2 := load("res://data/orders/easy_orders/tutorial_feet.tres")
		return [order1, order2]
	else:
		return OrderGenerator.generate_pool(POOL_SIZE)


# ── order lifecycle ─────────────────────────────────────────────
func confirm_orders(selected_indices: Array):
	GameState.active_orders.clear()
	GameState.completed_order_ids.clear()
	for idx in selected_indices:
		if idx < GameState.daily_order_pool.size():
			GameState.active_orders.append(GameState.daily_order_pool[idx])


func mark_order_complete(order_id: String):
	if order_id not in GameState.completed_order_ids:
		GameState.completed_order_ids.append(order_id)


func process_incomplete_orders():
	var rebate: int = 0
	for order in GameState.active_orders:
		if order.id not in GameState.completed_order_ids:
			rebate += int(round(order.raw_cost() * INCOMPLETE_REBATE))
	if rebate > 0:
		GameState.gold += rebate
	GameState.active_orders.clear()
	GameState.completed_order_ids.clear()


func get_order_total() -> int:
	var total = 0
	for order in GameState.active_orders:
		total += order.raw_cost()
	return total
