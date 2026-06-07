extends PanelContainer

@onready var texture_rect = $VBoxContainer/TextureRect
@onready var name_label = $VBoxContainer/Name
@onready var description_label = $VBoxContainer/Description
@onready var try_button = $VBoxContainer/TryButton

func setup(magazine: MagazineData, on_try: Callable):
	name_label.text = magazine.magazine_name
	description_label.text = magazine.description
	if magazine.image:
		texture_rect.texture = magazine.image
	try_button.pressed.connect(on_try)
	_check_sold_out(magazine)

func _check_sold_out(magazine: MagazineData):
	# check if any lockable coupon exists for this magazine's rarities
	var has_available = false
	for coupon in GameState.COUPON_DB.coupons:
		if coupon.id not in GameState.unlocked_coupon_ids:
			var weight = _get_weight_for_rarity(magazine, coupon.rarity)
			if weight > 0.0:
				has_available = true
				break
	if not has_available:
		try_button.text = "Sold Out"
		try_button.disabled = true
		modulate = Color(0.6, 0.6, 0.6, 1.0)

func _get_weight_for_rarity(magazine: MagazineData, rarity: CouponData.rarity_levels) -> float:
	match rarity:
		CouponData.rarity_levels.COMMON:   return magazine.common_weight
		CouponData.rarity_levels.UNCOMMON: return magazine.uncommon_weight
		CouponData.rarity_levels.RARE:     return magazine.rare_weight
		CouponData.rarity_levels.MYTHIC:   return magazine.mythic_weight
		CouponData.rarity_levels.WIZARDRY: return magazine.wizardry_weight
	return 0.0
