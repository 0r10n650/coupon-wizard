extends Node

@onready var slider: HSlider = %InterestSlider
@onready var label: Label = %InterestLabel

func _ready() -> void:
	slider.value_changed.connect(_on_slider_changed)
	label.text = "%d%%" % slider.value

func _on_slider_changed(value: float) -> void:
	label.text = "%d%%" % value
