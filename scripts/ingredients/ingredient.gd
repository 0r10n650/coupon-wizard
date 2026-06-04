class_name Ingredient
extends Resource

enum Element { NONE, EARTH, FIRE, WATER, AIR }

@export var name: String
@export var price: int
@export var image: Texture2D
@export var element: Element
@export var tags: Array[String]

func _to_string() -> String:
	return "Ingredient(name: %s, price: %s, element: %s, tags: %s)" % [name, price, Element.keys()[element] if element in Element.values() else element, tags]
