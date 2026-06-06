class_name OrderSlot
extends RefCounted

enum State {
	ACTIVE,          # has an order, player can interact
	LOCKED_HIDDEN,   # exists but player doesn't know it's there
	LOCKED_VISIBLE,  # player can see the slot but can't buy it yet
	BUYABLE,         # the next purchasable slot, price shown
}

var state: State
var order: Order      # null unless ACTIVE
var unlock_cost: int  # only meaningful when BUYABLE or LOCKED_VISIBLE


func _init(p_state: State, p_order: Order = null, p_cost: int = 0) -> void:
	state = p_state
	order = p_order
	unlock_cost = p_cost
