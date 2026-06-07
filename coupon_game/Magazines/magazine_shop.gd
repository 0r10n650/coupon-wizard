extends Control

@onready var attempts_label = $VBoxContainer/MarginContainer/AttemptsLabel
@onready var magazine_holder = $VBoxContainer/MagazineHolder
@onready var back_button = $VBoxContainer/NavigationBar/HBoxContainer/BackButton

const MAGAZINE_SCENE = preload("res://coupon_game/Magazines/magazine.tscn")

func _ready():
	_build_magazines()
	_update_attempts_label()

func _build_magazines():
	for child in magazine_holder.get_children():
		child.queue_free()
	for magazine in GameState.MAGAZINE_DB.magazines:
		var card = MAGAZINE_SCENE.instantiate()
		magazine_holder.add_child(card)
		card.setup(magazine, _on_try_pressed.bind(magazine))

func _update_attempts_label():
	attempts_label.text = "Attempts %d/%d" % [
		GameState.coupon_attempts_remaining,
		GameState.get_max_coupon_attempts()
	]

func _on_try_pressed(magazine: MagazineData):
	if GameState.coupon_attempts_remaining <= 0:
		return
	var rarity = GameState.roll_rarity(magazine)
	
	# only pick from locked coupons first
	var candidates: Array = []
	for coupon in GameState.COUPON_DB.coupons:
		if coupon.rarity == rarity and coupon.id not in GameState.unlocked_coupon_ids:
			candidates.append(coupon)
	
	# if all of that rarity are unlocked, nothing to give
	if candidates.is_empty():
		print("All coupons of this rarity already unlocked!")
		# don't consume an attempt if nothing to unlock
		return
	
	var chosen: CouponData = candidates[randi() % candidates.size()]
	GameState.pending_coupon = chosen
	GameState.coupon_attempts_remaining -= 1
	SceneLoader.load_scene("res://coupon_game/maze_minigame.tscn")

func _show_result(coupon: CouponData):
	if coupon == null:
		print("No coupon to show")
		return
	# for now just print, you can replace with a popup later
	print("Unlocked: ", coupon.name, " (", coupon.rarity, ")")

func _on_back_pressed():
	SceneLoader.load_scene("res://Scenes/ui/CouponUpgrades/coupon_upgrade_scene.tscn")
