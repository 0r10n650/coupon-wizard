extends Control

@onready var equipped_coupons = $VBoxContainer/EquippedCoupons
@onready var museum = $VBoxContainer/Museum
@onready var loadout_row = %LoadoutRow

@onready var common_header = $VBoxContainer/Museum/ScrollContainer/VBoxContainer2/VBoxContainer/CommonHeader
@onready var common_grid = $VBoxContainer/Museum/ScrollContainer/VBoxContainer2/VBoxContainer/CommonGrid
@onready var uncommon_header = $VBoxContainer/Museum/ScrollContainer/VBoxContainer2/VBoxContainer2/UncommonHeader
@onready var uncommon_grid = $VBoxContainer/Museum/ScrollContainer/VBoxContainer2/VBoxContainer2/UncommonGrid
@onready var rare_header = $VBoxContainer/Museum/ScrollContainer/VBoxContainer2/VBoxContainer3/RareHeader
@onready var rare_grid = $VBoxContainer/Museum/ScrollContainer/VBoxContainer2/VBoxContainer3/RareGrid
@onready var mythic_header = $VBoxContainer/Museum/ScrollContainer/VBoxContainer2/VBoxContainer4/MythicHeader
@onready var mythic_grid = $VBoxContainer/Museum/ScrollContainer/VBoxContainer2/VBoxContainer4/MythicGrid
@onready var wizardry_header = $VBoxContainer/Museum/ScrollContainer/VBoxContainer2/VBoxContainer5/WizardryHeader
@onready var wizardry_grid = $VBoxContainer/Museum/ScrollContainer/VBoxContainer2/VBoxContainer5/WizardryGrid
@onready var drag_layer = $DragLayer

const COUPON_SCENE = preload("res://Scenes/ui/Coupon.tscn")
const SLOT_CARD_SIZE = Vector2(95, 110)

var drag_coupon_id: String = ""
var drag_source_slot: int = -1
var drag_ghost: Control = null
var _hovered_slot: int = -1
var slot_cards: Array = []
var collection_cards: Array = []  # track all museum cards for hit testing

func _ready():
	_setup_collapsible(common_header, common_grid)
	_setup_collapsible(uncommon_header, uncommon_grid)
	_setup_collapsible(rare_header, rare_grid)
	_setup_collapsible(mythic_header, mythic_grid)
	_setup_collapsible(wizardry_header, wizardry_grid)
	_build_loadout()
	_build_museum()

func _setup_collapsible(header: Button, grid: GridContainer):
	var title = header.text
	header.text = "▼ " + title
	header.pressed.connect(func():
		grid.visible = !grid.visible
		header.text = ("▼ " if grid.visible else "▶ ") + title
	)

func _build_loadout():
	slot_cards.clear()
	for child in loadout_row.get_children():
		child.queue_free()
	for i in range(5):
		var slot = _make_slot_card(i)
		slot_cards.append(slot)
		loadout_row.add_child(slot)

func _make_slot_card(slot_idx: int) -> Control:
	var unlocked = slot_idx < GameState.coupon_slots
	var root = Control.new()
	root.custom_minimum_size = SLOT_CARD_SIZE
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.set_meta("slot_idx", slot_idx)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(panel)

	if not unlocked:
		root.modulate = Color(0.38, 0.38, 0.38, 0.65)
		_add_centered_label(panel, "Slot %d\n🔒" % (slot_idx + 1), 10)
	else:
		var equipped_id = ""
		if slot_idx < GameState.equipped_coupon_ids.size():
			equipped_id = GameState.equipped_coupon_ids[slot_idx]
		if equipped_id != "":
			var data = _find_coupon_data(equipped_id)
			if data:
				var card = COUPON_SCENE.instantiate()
				card.set_anchors_preset(Control.PRESET_FULL_RECT)
				card.mouse_filter = Control.MOUSE_FILTER_PASS
				card.data = data
				panel.add_child(card)
		else:
			root.modulate = Color(0.7, 0.7, 0.7, 0.5)
			_add_centered_label(panel, "Slot %d\n(empty)" % (slot_idx + 1), 10)
	return root

func _build_museum():
	collection_cards.clear()
	for grid in [common_grid, uncommon_grid, rare_grid, mythic_grid, wizardry_grid]:
		for child in grid.get_children():
			child.queue_free()
	for coupon in GameState.COUPON_DB.coupons:
		var card = COUPON_SCENE.instantiate()
		card.data = coupon
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if coupon.id not in GameState.unlocked_coupon_ids:
			card.modulate = Color(0.3, 0.3, 0.3, 0.75)
		else:
			card.set_meta("coupon_id", coupon.id)
			collection_cards.append(card)
		_get_grid_for_rarity(coupon.rarity).add_child(card)

func _get_grid_for_rarity(rarity) -> GridContainer:
	match rarity:
		CouponData.rarity_levels.COMMON:   return common_grid
		CouponData.rarity_levels.UNCOMMON: return uncommon_grid
		CouponData.rarity_levels.RARE:     return rare_grid
		CouponData.rarity_levels.MYTHIC:   return mythic_grid
		CouponData.rarity_levels.WIZARDRY: return wizardry_grid
	return common_grid

# returns the coupon_id of whichever collection card the point lands in, or ""
func _collection_card_at(global_pt: Vector2) -> String:
	for card in collection_cards:
		if not card.is_visible_in_tree():
			continue
		var rect = Rect2(card.global_position, card.size)
		if rect.has_point(global_pt):
			return card.get_meta("coupon_id")
	return ""

func _slot_index_at(global_pt: Vector2) -> int:
	for i in range(min(slot_cards.size(), GameState.coupon_slots)):
		var rect = Rect2(slot_cards[i].global_position, slot_cards[i].size)
		if rect.has_point(global_pt):
			return i
	return -1

func _input(ev: InputEvent):
	if not (ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT):
		return

	if ev.pressed:
		# check slot pickup first
		var slot_hit = _slot_index_at(ev.global_position)
		if slot_hit != -1:
			var equipped_id = ""
			if slot_hit < GameState.equipped_coupon_ids.size():
				equipped_id = GameState.equipped_coupon_ids[slot_hit]
			if equipped_id != "":
				_start_drag(equipped_id, slot_hit)
				return

		# then check collection pickup
		var coupon_id = _collection_card_at(ev.global_position)
		if coupon_id != "":
			if coupon_id in GameState.equipped_coupon_ids:
				return
			_start_drag(coupon_id, -1)
	else:
		# mouse released
		if drag_coupon_id == "":
			return
		var slot_hit = _slot_index_at(ev.global_position)
		if slot_hit != -1:
			_commit_drop(slot_hit)
		else:
			_cancel_drag()

func _start_drag(coupon_id: String, source_slot: int):
	drag_coupon_id = coupon_id
	drag_source_slot = source_slot
	if drag_ghost:
		drag_ghost.queue_free()
	drag_ghost = _build_ghost(coupon_id)
	drag_layer.add_child(drag_ghost)
	drag_ghost.pivot_offset = drag_ghost.custom_minimum_size / 2.0
	drag_ghost.position = get_global_mouse_position() - drag_ghost.pivot_offset
	drag_ghost.scale = Vector2(0.7, 0.7)
	var t = create_tween()
	t.tween_property(drag_ghost, "scale", Vector2(1.1, 1.1), 0.1)
	t.tween_property(drag_ghost, "scale", Vector2(1.0, 1.0), 0.07)

func _build_ghost(coupon_id: String) -> Control:
	var root = Control.new()
	root.custom_minimum_size = SLOT_CARD_SIZE
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.modulate = Color(1, 1, 1, 0.85)
	root.add_child(panel)
	var data = _find_coupon_data(coupon_id)
	if data:
		var card = COUPON_SCENE.instantiate()
		card.set_anchors_preset(Control.PRESET_FULL_RECT)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.data = data
		panel.add_child(card)
	return root

func _commit_drop(target_slot: int):
	var target_id = ""
	if target_slot < GameState.equipped_coupon_ids.size():
		target_id = GameState.equipped_coupon_ids[target_slot]
	if drag_source_slot == -1:
		if target_id != "":
			GameState.unequip_coupon(target_slot)
		GameState.equip_coupon(drag_coupon_id, target_slot)
	else:
		if target_id != "":
			GameState.equip_coupon(target_id, drag_source_slot)
		else:
			GameState.unequip_coupon(drag_source_slot)
		GameState.equip_coupon(drag_coupon_id, target_slot)
	GameState.save_game()
	_cancel_drag()
	_build_loadout()
	_build_museum()

func _cancel_drag():
	drag_coupon_id = ""
	drag_source_slot = -1
	_hovered_slot = -1
	if drag_ghost:
		drag_ghost.queue_free()
		drag_ghost = null
	for i in range(slot_cards.size()):
		if i < GameState.coupon_slots:
			slot_cards[i].modulate = Color.WHITE
		else:
			slot_cards[i].modulate = Color(0.38, 0.38, 0.38, 0.65)

func _process(_delta):
	if drag_ghost == null or drag_coupon_id == "":
		return
	drag_ghost.position = get_global_mouse_position() - drag_ghost.pivot_offset
	var hit = _slot_index_at(get_global_mouse_position())
	if hit != _hovered_slot:
		if _hovered_slot != -1 and _hovered_slot < slot_cards.size():
			slot_cards[_hovered_slot].modulate = Color.WHITE
		if hit != -1 and hit < slot_cards.size():
			_bump_card(slot_cards[hit])
			slot_cards[hit].modulate = Color(1.15, 1.15, 0.6)
		_hovered_slot = hit

func _bump_card(card: Control):
	var t = create_tween()
	t.tween_property(card, "scale", Vector2(1.12, 1.12), 0.07).set_trans(Tween.TRANS_BACK)
	t.tween_property(card, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK)

func _add_centered_label(parent: Control, text: String, font_size: int):
	var lbl = Label.new()
	lbl.text = text
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(lbl)

func _find_coupon_data(id: String):
	for coupon in GameState.COUPON_DB.coupons:
		if coupon.id == id:
			return coupon
	return null

func _on_back_pressed():
	SceneLoader.load_scene("res://Scenes/Management/management_screen.tscn")


func _on_unlock_coupons_button_pressed():
	SceneLoader.load_scene("res://coupon_game/Magazines/magazine_shop.tscn")
