extends Button

const GAME_SCENE_PATH : String = "res://scenes/game.tscn"

func load_title_screen():
	ResourceLoader.load_threaded_request(GAME_SCENE_PATH)

# Called when the node enters the scene tree for the first time.
func _ready():
	load_title_screen()

func _on_pressed():
	print("Start game")
	# Obtain the resource now that we need it
	var game_scene = ResourceLoader.load_threaded_get(GAME_SCENE_PATH)
	# Instantiate the enemy scene and add it to the current scene
	var game = game_scene.instantiate()
	var title_screen_container = get_node("../../../")
	var scene_container = get_node("../../../../SceneContainer")
	for child in scene_container.get_children():
		scene_container.remove_child(child)
		child.queue_free()
		
	scene_container.add_child(game)
	$"../../AnimationPlayer".play("hide_ui")
