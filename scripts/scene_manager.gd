extends Node3D


const GAME_SCENE_PATH : String = "res://scenes/mini_game_rental.tscn"

func load_game():
	ResourceLoader.load_threaded_request(GAME_SCENE_PATH)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	load_game()
	$CanvasLayer/TitleScreen/%Button.pressed.connect(_on_button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_button_pressed():
	print("Start game")
	start_game()
	
func start_game():
	# Obtain the resource now that we need it
	var game_scene = ResourceLoader.load_threaded_get(GAME_SCENE_PATH)
	# Instantiate the enemy scene and add it to the current scene
	var game = game_scene.instantiate()
	var scene_container = %SceneContainer
	for child in scene_container.get_children():
		scene_container.remove_child(child)
		child.queue_free()
		
	scene_container.add_child(game)
	$"CanvasLayer/TitleScreen/AnimationPlayer".play("hide_ui")
	$TitleScreen.queue_free()

