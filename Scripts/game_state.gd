extends Node

const SAVE_PATH = "user://save_game.save"

var current_day: int = 2
var gold: int = 0
var debt: int = 500
var last_scene_path: String = "res://Scenes/shopping.tscn"

var upgrades = {
	"coupon_time": 0,
	"coupon_retries": 0,
	"coupon_rect_percent": 0,
	"coupon_circle_percent": 0,
	"coupon_hexagon_percent": 0,
	"coupon_triangle_percent": 0,
	"coupon_star_percent": 0,
	"coupon_gear_percent": 0,
	"checkout_combo_time": 0,
	"checkout_shake_reduction": 0,
	"checkout_shake_delay": 0,
	"checkout_bonus_arrow": 0,
	"shopping_time": 0,
	"coupon_slots": 0,
}

var daily_state = {
	"coupons_tried": [], # array of coupon IDs
	"retries_used": 0,
	"successful_coupons": [] # array of dictionaries e.g. {"id": 1, "discount_percent": 5}
}

var cart_items: Array = []

func _ready():
	load_game()

func save_game():
	var save_dict = {
		"current_day": current_day,
		"gold": gold,
		"debt": debt,
		"last_scene_path": last_scene_path,
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
			unlocked_coupon_ids = data.get("unlocked_coupon_ids", [])
			equipped_coupon_ids = data.get("equipped_coupon_ids", [])
			coupon_slots = data.get("coupon_slots", 2)
			if data.has("upgrades"):
				for key in data["upgrades"]:
					if upgrades.has(key):
						upgrades[key] = data["upgrades"][key]
				coupon_slots = int(get_upgrade_value("coupon_slots"))
		file.close()

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_current_scene(path: String):
	last_scene_path = path
	save_game()

func reset_game():
	current_day = 2
	gold = 0
	debt = 500
	for key in upgrades:
		upgrades[key] = 0
	daily_state = {
		"coupons_tried": [],
		"retries_used": 0,
		"successful_coupons": []
	}
	cart_items.clear()
	unlocked_coupon_ids.clear()
	equipped_coupon_ids.clear()
	coupon_slots = 2

	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	
	print("Game reset to Day 2 defaults.")

func advance_day():
	if debt > 0:
		debt = int(debt * 1.30)
	current_day += 1
	# Reset daily state
	daily_state = {
		"coupons_tried": [],
		"retries_used": 0,
		"successful_coupons": []
	}
	save_game()

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
			save_game()
			return true
	return false

var upgrade_tiers = {
	"coupon_time": {
		"costs": [10, 1000, 5000, 20000],
		"values": [5.0, 6.0, 11.0, 20.0, 35.0] # base 5s, +1s, +5s, etc.
	},
	"coupon_retries": {
		"costs": [50, 500, 2500],
		"values": [0, 1, 2, 3]
	},
	"coupon_rect_percent": {
		"costs": [50, 250, 1200, 5000],
		"values": [5, 10, 15, 20, 25]
	},
	"coupon_circle_percent": {
		"costs": [250, 1000, 4500, 14000],
		"values": [20, 30, 42, 55, 70]
	},
	"coupon_hexagon_percent": {
		"costs": [500, 2000, 7500, 20000],
		"values": [35, 50, 65, 85, 110]
	},
	"coupon_triangle_percent": {
		"costs": [100, 500, 2500, 9000],
		"values": [12, 18, 25, 35, 45]
	},
	"coupon_star_percent": {
		"costs": [1000, 4000, 12000, 30000],
		"values": [55, 75, 100, 130, 160]
	},
	"coupon_gear_percent": {
		"costs": [2000, 7500, 20000, 45000],
		"values": [80, 110, 145, 185, 230]
	},
	"checkout_combo_time": {
		"costs": [20, 200, 2000],
		"values": [3.0, 4.0, 5.0, 6.0]
	},
	"checkout_shake_reduction": {
		"costs": [50, 500, 5000],
		"values": [0.15, 0.12, 0.09, 0.06]
	},
	"checkout_shake_delay": {
		"costs": [50, 500, 5000],
		"values": [0, 5, 10, 15]
	},
	"checkout_bonus_arrow": {
		"costs": [100, 500, 1500, 4000, 10000, 25000],
		"values": [1, 2, 3, 4, 5, 6, 7]
	},
	"shopping_time": {
		"costs": [50, 200, 1000, 5000],
		"values": [30.0, 45.0, 60.0, 90.0, 120.0]
	},
	"coupon_slots": {
		"costs": [200, 500, 1500],
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

# Helpers for getting upgraded values
func get_max_retries() -> int: return get_upgrade_value("coupon_retries")
func get_combo_time_limit() -> float: return get_upgrade_value("checkout_combo_time")
func get_shake_reduction() -> float: return 0.0
func get_shake_delay() -> int: return 20
func get_decay_increment() -> float: return get_upgrade_value("checkout_shake_reduction")
func get_decay_delay_threshold() -> int: return get_upgrade_value("checkout_shake_delay")
func get_maze_time_limit() -> float: return get_upgrade_value("coupon_time")
func get_bonus_arrow_value() -> int: return int(get_upgrade_value("checkout_bonus_arrow"))
func get_shopping_time_limit() -> float: return get_upgrade_value("shopping_time")

func get_coupon_percent(coupon_id: int) -> int:
	var maze_type = (coupon_id - 1) % 6
	match maze_type:
		1: return int(get_upgrade_value("coupon_rect_percent"))
		4: return int(get_upgrade_value("coupon_circle_percent"))
		3: return int(get_upgrade_value("coupon_hexagon_percent"))
		2: return int(get_upgrade_value("coupon_triangle_percent"))
		0: return int(get_upgrade_value("coupon_star_percent"))
		5: return int(get_upgrade_value("coupon_gear_percent"))
		_: return 1

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
	if daily_state["retries_used"] < get_max_retries():
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
	
func add_cart_item(item) -> void:
	cart_items.append(item)

# each coupon: id, name, description, tier, type, value, required_count (opt), multiplier (opt)
# types: percent_off | flat_off | buy_n_participating_flat | multiply_previous
var unlocked_coupon_ids: Array = []
var equipped_coupon_ids: Array = []
var coupon_slots: int = 2  # upgradeable to 5

const ALL_COUPONS: Array = [
	# low tier
	{
		"id": "low_pct",
		"name": "5% Off",
		"description": "5% off scanned total",
		"tier": "low",
		"type": "percent_off",
		"value": 5.0,
	},
	{
		"id": "low_flat",
		"name": "5G Off",
		"description": "Flat 5G off",
		"tier": "low",
		"type": "flat_off",
		"value": 5.0,
	},
	{
		"id": "low_buy10",
		"name": "Bulk Deal",
		"description": "Buy 10 participating items, get 10G off",
		"tier": "low",
		"type": "buy_n_participating_flat",
		"value": 10.0,
		"required_count": 10,
	},
	# medium tier
	{
		"id": "med_pct",
		"name": "15% Off",
		"description": "15% off scanned total",
		"tier": "medium",
		"type": "percent_off",
		"value": 15.0,
	},
	{
		"id": "med_buy5",
		"name": "5-Pack Deal",
		"description": "Buy 5 participating items, get 5G off",
		"tier": "medium",
		"type": "buy_n_participating_flat",
		"value": 5.0,
		"required_count": 5,
	},
	{
		"id": "med_double",
		"name": "Double Up",
		"description": "Double the effect of the previous coupon",
		"tier": "medium",
		"type": "multiply_previous",
		"multiplier": 2.0,
	},
	# high tier
	{
		"id": "high_pct",
		"name": "25% Off",
		"description": "25% off scanned total",
		"tier": "high",
		"type": "percent_off",
		"value": 25.0,
	},
	{
		"id": "high_triple",
		"name": "Triple Threat",
		"description": "Triple the effect of the previous coupon",
		"tier": "high",
		"type": "multiply_previous",
		"multiplier": 3.0,
	},
]


func unlock_coupon(id: String):
	if id not in unlocked_coupon_ids:
		unlocked_coupon_ids.append(id)


func equip_coupon(id: String, slot: int):
	if slot >= coupon_slots:
		push_warning("GameState: tried to equip coupon into locked slot %d" % slot)
		return
	while equipped_coupon_ids.size() <= slot:
		equipped_coupon_ids.append("")
	equipped_coupon_ids[slot] = id


func unequip_coupon(slot: int):
	if slot < equipped_coupon_ids.size():
		equipped_coupon_ids[slot] = ""


func get_equipped_coupons() -> Array:
	var result = []
	for id in equipped_coupon_ids:
		if id == "":
			continue
		for c in ALL_COUPONS:
			if c["id"] == id:
				result.append(c)
				break
	return result


func get_unlocked_coupons() -> Array:
	var result = []
	for id in unlocked_coupon_ids:
		for c in ALL_COUPONS:
			if c["id"] == id:
				result.append(c)
				break
	return result


func upgrade_coupon_slots() -> bool:
	var ok = purchase_upgrade("coupon_slots")
	if ok:
		coupon_slots = int(get_upgrade_value("coupon_slots"))
	return ok
