class_name MagazineData
extends Resource

@export var magazine_name: String
@export var description: String
@export var image: Texture2D

# weights for each rarity — higher = more likely
@export var common_weight: float = 0.0
@export var uncommon_weight: float = 0.0
@export var rare_weight: float = 0.0
@export var mythic_weight: float = 0.0
@export var wizardry_weight: float = 0.0
