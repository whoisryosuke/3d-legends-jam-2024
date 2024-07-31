extends Control

const LIST_ITEM_SCENE_PATH : String = "res://scenes/game_list_item.tscn"
const constants = preload("res://scripts/constants.gd")
@onready var container = $AspectRatioContainer/Content/ComboBox/GridContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	ResourceLoader.load_threaded_request(LIST_ITEM_SCENE_PATH)
	
	var list_item_scene = ResourceLoader.load_threaded_get(LIST_ITEM_SCENE_PATH)
	for button_index in len(constants.BUTTON_COMBOS):
		# Get text from constants using our array indexing trick
		var combo = constants.BUTTON_COMBOS[button_index]
		# Condense combo array into a string
		var current_button_text = ""
		for text in combo:
			current_button_text += text + " "
		var game_name = constants.RECIPES[button_index]
		
		# Instantiate a new list item
		var list_item = list_item_scene.instantiate()
		# Update the text fields
		list_item.get_node("GameName").text = game_name
		list_item.get_node("ButtonCombo").text = current_button_text
		# Add it to the container
		container.add_child(list_item)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
