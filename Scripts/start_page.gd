extends Node2D
class_name  start_page

const jordo_scene = preload("res://coupon_game/coupon_game_test.tscn")
const o_scene = preload("res://Scenes/shopping.tscn")
const checkout_scene = preload("res://checkout_minigame/checkout_minigame_3d.tscn")

func _on_jordos_button_pressed():
	get_tree().change_scene_to_packed(jordo_scene)

func _on_o_button_pressed():
	get_tree().change_scene_to_packed(o_scene)


func _on_checkout_game_pressed():
	get_tree().change_scene_to_packed(checkout_scene)
