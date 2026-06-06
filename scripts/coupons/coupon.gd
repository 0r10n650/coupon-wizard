@tool
extends Control
class_name Coupon

@export var data: CouponData:
	set(v):
		data = v
		_update_ui()

@export var image: Texture2D:
	set(v):
		image = v
		_update_ui()

@onready var textrec = $PanelContainer/TextureRect
@onready var label = $PanelContainer/Label

func _ready():
	_update_ui()

func _update_ui():
	if not is_node_ready():
		return
	if data:
		label.text = data.name
	if image:
		textrec.texture = image
