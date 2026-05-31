extends PanelContainer

@export var ingredient: Ingredient
var quantity: int = 0

# UI references
@onready var item_image = $VBoxContainer/ItemImage
@onready var item_label = $VBoxContainer/ItemLabel
@onready var item_count = $VBoxContainer/HBoxContainer/ItemCount

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_image.texture = ingredient.image
	item_label.text = "%s (%dg)" % [ingredient.name, ingredient.price]
	set_quantity(0)

func set_quantity(value: int) -> void:
	quantity = value
	item_count.text = str(quantity)

signal quantity_changed(ingredient: Ingredient, delta: int)

func _on_minus_pressed():
	if quantity > 0:
		set_quantity(quantity - 1)
		quantity_changed.emit(ingredient, -1)

func _on_plus_pressed():
	set_quantity(quantity + 1)
	quantity_changed.emit(ingredient, 1)
