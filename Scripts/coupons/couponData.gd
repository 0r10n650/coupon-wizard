class_name CouponData
extends Resource


enum rarity_levels {
	COMMON,
	UNCOMMON,
	RARE,
	MYTHIC,
	WIZARDRY
}

enum MazeType {
	STAR,
	RECT,
	TRIANGLE,
	HEXAGON,
	CIRCLE,
	COMPLEX
}


@export var name: String
@export var description: String
@export var effect: CouponEffect
@export var rarity: rarity_levels
@export var id: String
@export var maze_type: MazeType = MazeType.CIRCLE

func apply(successful: Array, 
	destroyed: Array, 
	total: int, 
	equipped_ids: Array = [], 
	current_slot: int = 0) -> int:
	return effect.apply(successful, destroyed, total, equipped_ids, current_slot)
