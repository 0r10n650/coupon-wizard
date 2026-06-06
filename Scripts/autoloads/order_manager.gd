extends Node

const POOL_SIZE        = 5
const INCOMPLETE_REBATE = 0.5


func _ready():
	pass  # pools now live in ShelfRegistry / OrderGenerator, nothing to preload


# Called by GameState.begin_day() — generates and caches the daily pool exactly once.
func generate_order_pool() -> Array[Order]:
	if GameState.current_day == 1:
		return _day1_pool()
	if GameState.current_day == 2:
		return _day2_pool()
	return OrderGenerator.generate_pool(POOL_SIZE)


# ── day-specific pools ──────────────────────────────────────────

func _day1_pool() -> Array[Order]:
	# Slot 0 is the tutorial; remaining 4 are generated but hidden.
	var pool: Array[Order] = []
	pool.append(_load_tutorial("tutorial_frog"))
	pool.append_array(OrderGenerator.generate_pool(POOL_SIZE - 1))
	return pool


func _day2_pool() -> Array[Order]:
	var pool: Array[Order] = []
	pool.append(_load_tutorial("tutorial_dust"))
	pool.append_array(OrderGenerator.generate_pool(POOL_SIZE - 1))
	return pool


func _load_tutorial(name: String) -> Order:
	var path  = "res://data/orders/easy_orders/%s.tres" % name
	var order = load(path)
	if not order is Order:
		push_error("OrderManager: tutorial resource missing or wrong type: %s" % path)
	return order


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
