extends Node

const SAVE_PATH = "user://save_game.save"
const REWARD_MULTIPLIER = 1.15

var current_day: int = 1
var gold: int = 0
var debt: int = 500
var daily_interest: float = .10
var last_scene_path: String = "res://Scenes/Shopping/shopping.tscn"

var upgrades = {
	"coupon_time": 0,
	"coupon_retries": 0,
	"checkout_time": 0,
	"checkout_vision": 0,
	"shopping_time": 0,
	"orders": 0,
	"order_rerolls": 0,
	"coupon_slots": 0,
}

var daily_state = {
	"coupons_tried": [], # array of coupon IDs
	"retries_used": 0,
	"successful_coupons": [] # array of dictionaries e.g. {"id": 1, "discount_percent": 5}
}

var cart_items: Array = []
# confirmed orders for today — populated when player hits "Start Shopping"
var active_orders: Array = []
# pool generated at start of each day — discarded after selection
var daily_order_pool: Array[Order] = []
# how many orders the player can select — driven by upgrade
var max_orders: int = 2
var completed_order_ids: Array = []
var rerolls_remaining: int     = 0
var unlocked_order_slots: int = 1

var successful_items = []
var destroyed_items = []
var discount = 0

var unlocked_coupon_ids: Array = []
var equipped_coupon_ids: Array = []
var coupon_slots: int = 2  # upgradeable to 5

const COUPON_DB = preload("res://data/coupons/CouponDatabase.tres")
const MAGAZINE_DB = preload("res://coupon_game/Magazines/MagazineDB.tres")
var pending_coupon: CouponData = null

var coupon_attempts_remaining: int = 1
var tier_completions: Dictionary = {
	"COMMON": 0,
	"UNCOMMON": 0,
	"RARE": 0,
	"MYTHIC": 0,
	"WIZARDRY": 0
}

func _ready():
	_add_default_coupons()
	load_game()

func save_game():
	var save_dict = {
		"current_day": current_day,
		"gold": gold,
		"debt": debt,
		"last_scene_path": last_scene_path,
		"completed_order_ids":  completed_order_ids,
		"rerolls_remaining":    rerolls_remaining,
		"unlocked_order_slots": unlocked_order_slots,
		"upgrades": upgrades,
		"unlocked_coupon_ids": unlocked_coupon_ids,
		"equipped_coupon_ids": equipped_coupon_ids,
		"coupon_slots": coupon_slots,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict))
		file.close()

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return # Use defaults
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var data = json.get_data()
			current_day = data.get("current_day", current_day)
			gold = data.get("gold", gold)
			debt = data.get("debt", debt)
			last_scene_path = data.get("last_scene_path", last_scene_path)
			if last_scene_path == "res://Scenes/shopping.tscn":
				last_scene_path = "res://Scenes/Shopping/shopping.tscn"
			completed_order_ids  = data.get("completed_order_ids", [])
			rerolls_remaining    = data.get("rerolls_remaining", 0)
			unlocked_order_slots = data.get("unlocked_order_slots", 2)
			unlocked_coupon_ids = data.get("unlocked_coupon_ids", [])
			equipped_coupon_ids = data.get("equipped_coupon_ids", [])
			coupon_slots = data.get("coupon_slots", 2)
			if data.has("upgrades"):
				for key in data["upgrades"]:
					if upgrades.has(key):
						upgrades[key] = data["upgrades"][key]
				coupon_slots = int(get_upgrade_value("coupon_slots"))
				if upgrades.get("orders", 0) > 0:
					max_orders = int(get_upgrade_value("orders"))
		file.close()

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_current_scene(path: String):
	last_scene_path = path
	save_game()

func reset_game(daily_interest: float):
	current_day = 1
	gold = 0
	debt = 500
	daily_interest = daily_interest
	print("Save reset to Day 1")
	print("Interest set at %.2f" % daily_interest)
	
	for key in upgrades:
		upgrades[key] = 0
		
	daily_state = {
		"coupons_tried": [],
		"retries_used": 0,
		"successful_coupons": []
	}
	active_orders.clear()
	daily_order_pool.clear()
	completed_order_ids.clear()
	rerolls_remaining    = 0
	max_orders           = 2
	unlocked_order_slots = 1
	cart_items.clear()
	unlocked_coupon_ids.clear()
	_add_default_coupons()
	equipped_coupon_ids.clear()
	coupon_slots = 2

	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func advance_day():
	current_day += 1
	if current_day == 2:
		unlocked_order_slots = 2
	OrderManager.process_incomplete_orders()
	if debt > 0:
		debt += daily_interest * debt
	# Reset daily state
	daily_state = {
		"coupons_tried": [],
		"retries_used": 0,
		"successful_coupons": []
	}
	# Refresh rerolls from the upgrade level
	rerolls_remaining = int(get_upgrade_value("order_rerolls"))
	successful_items.clear()
	destroyed_items.clear()
	cart_items.clear()
	coupon_attempts_remaining = get_max_coupon_attempts()
	begin_day()
	save_game()

# Call once when the upgrade screen opens for the day. Safe to call multiple
# times — the pool is only generated once per day.
func begin_day() -> void:
	daily_order_pool     = OrderManager.generate_order_pool()
	rerolls_remaining    = int(get_upgrade_value("order_rerolls"))
	save_game()


func get_unlocked_order_slots() -> int:
	return unlocked_order_slots

func get_order_slot_cost(slot_idx: int) -> int:
	var costs = [0, 50, 150, 300, 500]
	if slot_idx < costs.size():
		return costs[slot_idx]
	return 999999

func purchase_order_slot(slot_idx: int, cost: int) -> bool:
	if gold < cost:
		return false
	gold -= cost
	unlocked_order_slots = max(unlocked_order_slots, slot_idx + 1)
	save_game()
	return true

func add_gold(amount: int):
	gold += amount
	save_game()

func pay_debt(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		debt = max(0, debt - amount)
		save_game()
		return true
	return false

func can_afford(upgrade_name: String) -> bool:
	var cost = get_upgrade_cost(upgrade_name)
	return gold >= cost

func purchase_upgrade(upgrade_name: String) -> bool:
	if upgrades.has(upgrade_name):
		var cost = get_upgrade_cost(upgrade_name)
		if gold >= cost:
			gold -= cost
			upgrades[upgrade_name] += 1
			if upgrade_name == "coupon_slots":
				coupon_slots = int(get_upgrade_value("coupon_slots"))
			elif upgrade_name == "orders":
				max_orders = int(get_upgrade_value("orders"))
			save_game()
			return true
	return false

var upgrade_tiers = {
	"coupon_time": {
		"costs": [5, 10, 25, 50],
		"values": [5.0, 6.0, 11.0, 20.0, 35.0] # base 5s, +1s, +5s, etc.
	},
	"coupon_retries": {
		"costs": [5, 20, 40],
		"values": [0, 1, 2, 3]
	},
	"checkout_time": {
		"costs": [10, 25, 50, 100],
		"values": [7.0, 9.0, 11.0, 15.0] # Base is 5.0
	},
	"checkout_vision": {
		"costs": [15],
		"values": [1] # Base is 0 (1 arrow visible). Upgrade gives +1
	},
	"shopping_time": {
		"costs": [5, 10, 25, 50],
		"values": [30.0, 45.0, 60.0, 90.0, 120.0]
	},
	"orders": {
		"costs": [20, 40, 80],
		"values": [3, 4, 5]
	},
	"order_rerolls": {
		"costs": [15, 30],
		"values": [0, 1, 2]
	},
	"coupon_slots": {
		"costs": [15, 35, 75],
		"values": [2, 3, 4, 5]
	},
}

func get_upgrade_cost(upgrade_name: String) -> int:
	var level = upgrades.get(upgrade_name, 0)
	var costs = upgrade_tiers[upgrade_name]["costs"]
	if level < costs.size():
		return costs[level]
	return 999999 # Max level reached

func get_upgrade_value(upgrade_name: String) -> Variant:
	var level = upgrades.get(upgrade_name, 0)
	var values = upgrade_tiers[upgrade_name]["values"]
	if level < values.size():
		return values[level]
	return values[values.size() - 1]

func get_upgrade_next_value(upgrade_name: String) -> Variant:
	var level = upgrades.get(upgrade_name, 0) + 1
	var values = upgrade_tiers[upgrade_name]["values"]
	if level < values.size():
		return values[level]
	return null

# Helpers for getting upgraded values
func get_max_coupon_attempts() -> int:
	return get_upgrade_value("coupon_retries") + 1
func get_checkout_time_limit() -> float: return 5.0 if upgrades.get("checkout_time", 0) == 0 else get_upgrade_value("checkout_time")
func get_checkout_vision() -> int: return 0 if upgrades.get("checkout_vision", 0) == 0 else get_upgrade_value("checkout_vision")
func get_maze_time_limit() -> float: return get_upgrade_value("coupon_time")
func get_shopping_time_limit() -> float: return get_upgrade_value("shopping_time")

func get_coupon_percent(coupon_id: int) -> int:
	var maze_type = (coupon_id - 1) % 6
	match maze_type:
		1: return 5
		4: return 20
		3: return 35
		2: return 12
		0: return 55
		5: return 80
		_: return 1

func roll_rarity(magazine: MagazineData) -> CouponData.rarity_levels:
	var weights = [
		[CouponData.rarity_levels.COMMON,   magazine.common_weight],
		[CouponData.rarity_levels.UNCOMMON, magazine.uncommon_weight],
		[CouponData.rarity_levels.RARE,     magazine.rare_weight],
		[CouponData.rarity_levels.MYTHIC,   magazine.mythic_weight],
		[CouponData.rarity_levels.WIZARDRY, magazine.wizardry_weight],
	]
	var total = 0.0
	for w in weights:
		total += w[1]
	var roll = randf() * total
	var cumulative = 0.0
	for w in weights:
		cumulative += w[1]
		if roll <= cumulative:
			return w[0]
	return CouponData.rarity_levels.COMMON

func try_unlock_from_magazine(magazine: MagazineData) -> CouponData:
	var rarity = roll_rarity(magazine)
	var candidates: Array = []
	for coupon in GameState.COUPON_DB.coupons:
		if coupon.rarity == rarity and coupon.id not in GameState.unlocked_coupon_ids:
			candidates.append(coupon)
	if candidates.is_empty():
		for coupon in GameState.COUPON_DB.coupons:
			if coupon.rarity == rarity:
				candidates.append(coupon)
	if candidates.is_empty():
		return null
	var chosen: CouponData = candidates[randi() % candidates.size()]
	GameState.unlock_coupon(chosen.id)
	return chosen

func record_successful_coupon(coupon_id: int):
	var disc = get_coupon_percent(coupon_id)
	daily_state["successful_coupons"].append({
		"id": coupon_id,
		"discount_percent": disc
	})
	
func get_total_discount_percent() -> int:
	var total = 5 # Base 5% discount
	for c in daily_state["successful_coupons"]:
		total += int(round(c["discount_percent"]))
	return total

func can_try_coupon(coupon_id: int) -> bool:
	if not daily_state["coupons_tried"].has(coupon_id):
		return true
	if daily_state["retries_used"] < get_max_coupon_attempts():
		return true
	return false

func try_coupon(coupon_id: int):
	if daily_state["coupons_tried"].has(coupon_id):
		daily_state["retries_used"] += 1
	else:
		daily_state["coupons_tried"].append(coupon_id)

# Helpers for Shopping
func get_cart_total() -> int:
	var total = 0
	for item in cart_items:
		if item and "price" in item:
			total += int(round(item.price))
	return total
	
func add_cart_item(item: Ingredient) -> void:
	cart_items.append(item)

# each coupon: id, name, description, tier, type, value, required_count (opt), multiplier (opt)
# types: percent_off | flat_off | buy_n_participating_flat | multiply_previous

func unlock_coupon(id: String):
	if id not in unlocked_coupon_ids:
		unlocked_coupon_ids.append(id)

func equip_coupon(id: String, slot: int):
	if slot >= coupon_slots:
		push_warning("GameState: tried to equip coupon into locked slot %d" % slot)

	while equipped_coupon_ids.size() <= slot:
		equipped_coupon_ids.append("")
	equipped_coupon_ids[slot] = id

func _add_default_coupons():
	unlock_coupon("5p")
	unlock_coupon("5s")
	unlock_coupon("1pi")

func unequip_coupon(slot: int):
	if slot < equipped_coupon_ids.size():
		equipped_coupon_ids[slot] = ""


func get_equipped_coupons() -> Array:
	var result = []
	for id in equipped_coupon_ids:
		if id == "":
			continue
		for c in COUPON_DB.coupons:
			if c["id"] == id:
				result.append(c)
				break
	return result


func get_unlocked_coupons() -> Array:
	var result = []
	for id in unlocked_coupon_ids:
		for c in COUPON_DB.coupons:
			if c["id"] == id:
				result.append(c)
				break
	return result


func upgrade_coupon_slots() -> bool:
	var ok = purchase_upgrade("coupon_slots")
	if ok:
		coupon_slots = int(get_upgrade_value("coupon_slots"))
	return ok
