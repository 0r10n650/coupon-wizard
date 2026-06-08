extends Node

const EASY_ORDERS_PATH = "res://data/orders/easy_orders/"
const MEDIUM_ORDERS_PATH = "res://data/orders/medium_orders/"
const HARD_ORDERS_PATH = "res://data/orders/hard_orders/"


func generate_daily_orders() -> Array[Order]:
	var easy = _pick_from_pool(_load_pool(EASY_ORDERS_PATH), 2)
	var medium = _pick_from_pool(_load_pool(MEDIUM_ORDERS_PATH), 2)
	var hard = _pick_from_pool(_load_pool(HARD_ORDERS_PATH), 1)
	return easy + medium + hard

func _load_pool(path: String) -> Array[Order]:
	var pool: Array[Order] = []
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		push_error("Could not open order pool at: %s" % path)
		return pool
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			pool.append(load(path + fname) as Order)
		fname = dir.get_next()
	dir.list_dir_end()
	return pool

func _pick_from_pool(pool: Array[Order], count: int) -> Array[Order]:
	var shuffled := pool.duplicate()
	shuffled.shuffle()
	return shuffled.slice(0, count)
