extends Node

# ShelfRegistry — autoload as "ShelfRegistry"
#
# Loads all Ingredient resources at startup and organises them into
# categories for OrderGenerator to draw from.
#
# Cross-category items (e.g. Human Dust in both "humanoid" and "powder")
# are intentional — OrderGenerator deduplicates within a single order.

const INGREDIENT_DIR = "res://data/ingredients/"

# Populated in _ready(); keyed by filename stem (e.g. "bat_wings").
var _all: Dictionary = {}

# Category → Array[Ingredient].  Cross-listing is fine.
var _shelves: Dictionary = {
	"unicorn":   [],
	"humanoid":  [],
	"amphibian": [],
	"creature":  [],
	"powder":    [],
	"elemental": [],
	"exotic":    [],
}


func _ready() -> void:
	_load_all()
	_assign_categories()
	_validate()


# ── loading ──────────────────────────────────────────────────────

func _load_all() -> void:
	var dir = DirAccess.open(INGREDIENT_DIR)
	if not dir:
		push_error("ShelfRegistry: cannot open ingredient directory %s" % INGREDIENT_DIR)
		return
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var res = load(INGREDIENT_DIR + fname)
			if res is Ingredient:
				var key = fname.get_basename()
				_all[key] = res
			else:
				push_warning("ShelfRegistry: %s is not an Ingredient resource" % fname)
		fname = dir.get_next()
	dir.list_dir_end()


func _assign_categories() -> void:
	_put("unicorn",   ["unicorn_eyes", "unicorn_hair", "unicorn_horn"])
	_put("humanoid",  ["human_teeth", "human_dust", "goblin_toes", "yeti_fur"])
	_put("amphibian", ["frog_leg", "frog_eyes", "bat_wings"])
	_put("creature",  ["dragon_scale", "yeti_fur"])
	_put("powder",    ["shroom_dust", "moon_dust", "human_dust"])
	_put("elemental", ["light_stuff", "wet_stuff", "hot_stuff",
					   "dry_stuff", "hard_stuff", "angry_stuff", "purple_whatevers"])
	_put("exotic",    ["partridge_in_a_pear_tree"])


func _put(category: String, keys: Array) -> void:
	for key in keys:
		if _all.has(key):
			_shelves[category].append(_all[key])
		else:
			push_warning("ShelfRegistry: ingredient '%s' not found for category '%s'" % [key, category])


func _validate() -> void:
	for key in _all:
		var ingredient: Ingredient = _all[key]
		if ingredient.name == "":
			push_warning("ShelfRegistry: ingredient '%s' has no name set in its .tres file" % key)


# ── public API ───────────────────────────────────────────────────

func get_categories() -> Array:
	return _shelves.keys()


func get_items_in_category(category: String) -> Array:
	return _shelves.get(category, [])


func get_random_items_from_category(category: String, count: int) -> Array:
	var pool: Array = _shelves.get(category, []).duplicate()
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))


func get_ingredient(key: String) -> Ingredient:
	return _all.get(key, null)


func get_all_ingredients() -> Array:
	return _all.values()
