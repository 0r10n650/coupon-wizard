extends PanelContainer
class_name inventory_item_2D

var ingredient: Ingredient
var amount: int

@onready var amount_label = $PanelContainer/Panel/AmountLabel
@onready var image = $PanelContainer/Panel2/Image
@onready var nameLabel = $PanelContainer/Panel3/Name
@onready var priceLabel = $PanelContainer/Panel4/Price

func _init(_ingredient):
	ingredient = _ingredient
	amount = 1
	update_ui()

func increase_count():
	if amount == null:
		return
	
	amount += 1
	update_ui()

func update_ui():
	amount_label.text = "x" + str(amount)
	image.texture = ingredient.image
	nameLabel.text = ingredient.name
	priceLabel.text = str(ingredient.price) + "G"
	
