extends SceneTree
func _init():
    var scene = preload("res://Scenes/ui/CouponUpgrades/coupon_upgrade_scene.tscn")
    print("Loaded scene: ", scene)
    quit()
