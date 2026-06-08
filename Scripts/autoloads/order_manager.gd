extends Node

const REWARD_MULT = [1.15, 1.15, 1.25, 1.25, 1.5]
const POOL_SIZE = 5


# Called by GameState.begin_day() — generates and caches the daily pool exactly once.
func generate_order_pool() -> Array[Order]:
	# Day specific pools.
	if GameState.current_day == 1:
		var order1 := load("res://data/orders/easy_orders/tutorial_frog.tres")
		var pool: Array[Order] = [order1]
		pool.append_array(OrderGenerator.generate_pool(POOL_SIZE - 1))
		return pool
	elif GameState.current_day == 2:
		var order1 := load("res://data/orders/easy_orders/tutorial_eyes.tres")
		var order2 := load("res://data/orders/easy_orders/tutorial_feet.tres")
		var pool: Array[Order] = [order1, order2]
		pool.append_array(OrderGenerator.generate_pool(POOL_SIZE - 2))
		return pool
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
			rebate += int(round(order.raw_cost() * GameState.REBATE_FRACTION))
	if rebate > 0:
		GameState.gold += rebate
	GameState.active_orders.clear()
	GameState.completed_order_ids.clear()


func get_order_total() -> int:
	var total = 0
	for order in GameState.active_orders:
		total += order.raw_cost()
	return total
	
func fulfill_active_orders(successful_items: Array, damaged_items: Array) -> void:
	var remaining_successful = successful_items.duplicate()
	var remaining_damaged = damaged_items.duplicate()

	for order in GameState.active_orders:
		var ok = order.try_fulfill(remaining_successful, remaining_damaged)
		if not ok:
			# Caller can decide on penalty; for now just log.
			push_warning("Order '%s' could not be fulfilled." % order.title)
			continue

		# Consume the items this order used so they aren't double-counted.
		for ing in order.line_items:
			var needed = order.line_items[ing]

			var s_matches = remaining_successful.filter(func(i): return i == ing)
			for i in mini(s_matches.size(), needed):
				remaining_successful.erase(s_matches[i])
				needed -= 1

			if needed > 0:
				var d_matches = remaining_damaged.filter(func(i): return i == ing)
				for i in mini(d_matches.size(), needed):
					remaining_damaged.erase(d_matches[i])

	# Sell leftover items back at rebate value.
	var rebate = 0
	for item in remaining_successful + remaining_damaged:
		if item != null:
			rebate += int(floor(item.price * GameState.REBATE_FRACTION))

	GameState.gold += rebate
	GameState.pending_rebate = rebate
