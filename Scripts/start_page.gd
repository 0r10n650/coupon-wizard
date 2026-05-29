extends Node2D
class_name  start_page

const jordo_scene = preload("res://coupon_game/coupon_game_test.tscn")
const o_scene = preload("res://Scenes/shopping.tscn")
const carpy_scene = preload("res://tests/shoppingfordummies.tscn")

func _on_jordos_button_pressed():
	get_tree().change_scene_to_packed(jordo_scene)


func _on_o_button_pressed():
	get_tree().change_scene_to_packed(o_scene)


func _on_carpy_demo_pressed():
	get_tree().change_scene_to_packed(carpy_scene)
