extends Node

@onready var game_timer = $"../GameTimer"
@onready var next_timer = $"../NextTimer"
@onready var timer_text = $"../MiniGameRentalUI/%TimerText"
@onready var dialogue_text = $"../MiniGameRentalUI/%DialogueText"
@onready var remaining_counter_text = $"../MiniGameRentalUI/%RemainingCounter"
const ROBOT_MODEL_PATH = "res://scenes/gobot_static.tscn"
var rand = RandomNumberGenerator.new()

# Constants
const constants = preload("res://scripts/constants.gd")
const DEFAULT_GAME_TIME = 60
const END_POSITION = Vector3(-0.77, 0.0, -6.16)
const INITIAL_POSITIONS = [
	Vector3(1.9, 0.0, -6.16),
	Vector3(3.9, 0.0, -6.36),
	Vector3(7.1, 0.0, -6.26),
]
const NEW_POSITION = Vector3(11.1, 0.0, -6.26)
const EXIT_ANIMATION_ROTATE_TIME = 1
const EXIT_ANIMATION_WALK_TIME = 3
const EXIT_ANIMATION_STATES = [
	"ROTATE",
	"WALK",
]

# Game State
var playing = false
var paused = false
var completed = false
var current_index = 0
var button_combinations = [
	3,
	4,
]
var exit_animation_state_index = 0
var exit_animation_state_animating = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Start the game timer
	# TODO: Delay to a 1...2..3 countdown
	start_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	## Update UI
	# Update timer text UI
	var remaining_count = len(button_combinations) - current_index
	remaining_counter_text.text = str(remaining_count)
	
	# Update timer text UI
	timer_text.text = "00:00:" + str(int(game_timer.time_left))
	
	# Update dialogue (aka the required button sequence)
	var current_button_index = button_combinations[current_index]
	var current_game = constants.RECIPES[current_button_index]
	var current_button = constants.BUTTON_COMBOS[current_button_index]
	var current_button_text = ""
	for text in current_button:
		current_button_text += text + " "
		
		
	dialogue_text.text = current_game
	
	## Animations
	# Exit animation
	if exit_animation_state_animating:
		handle_exit_animation()

func handle_exit_animation():
	
	# Check if timer is over
	var timer = $"../ExitAnimation"
	if !timer.is_stopped():
		# Rotate or walk
		var customers = $"../Customers".get_children()
		match EXIT_ANIMATION_STATES[exit_animation_state_index]:
			"ROTATE":
				# Lerp rotation based on timer
				var time_interpolation = 1.0 - (timer.time_left / EXIT_ANIMATION_ROTATE_TIME)
				customers[0].rotation.y = lerp(customers[0].rotation.y, -90.0, time_interpolation)
				
				for customer_index in len(customers):
					if customer_index != 0:
						var customer = customers[customer_index]
						customer.rotation.y = lerp(customer.rotation.y, -90.0, time_interpolation)
				
			"WALK":
				# Lerp towards end point based on timer
				var time_interpolation = 1.0 - (timer.time_left / EXIT_ANIMATION_WALK_TIME)
				customers[0].position.x = lerp(customers[0].position.x + 1.0, END_POSITION.x + 1.0, time_interpolation) - 1.0
				
				# move everyone up too
				for customer_index in len(customers):
					if customer_index != 0:
						var customer = customers[customer_index]
						customer.position.x = lerp(customer.position.x, INITIAL_POSITIONS[customer_index - 1].x, time_interpolation)
				
	else:
		print("ANIMATION TIMER DONE!")
		# Move to next state and restart timer if needed
		if exit_animation_state_index == 0:
			print("Triggering walk animation")
			exit_animation_state_index += 1
			$"../ExitAnimation".start(EXIT_ANIMATION_WALK_TIME)
		else:
			print("Animation done!")
			# Done animating - reset state
			exit_animation_state_animating = false
			exit_animation_state_index = 0
			# Get rid of the first child
			var customers = $"../Customers".get_children()
			customers[0].queue_free()
	

func _input(event):
	# Restart game
	if(game_timer.is_stopped() and Input.is_action_just_pressed("Cross")):
		restart_game()
	# Pause game
	if(!game_timer.is_stopped() and Input.is_action_just_pressed("Start")):
		paused = !paused
		if paused:
			pause_game()
		else:
			unpause_game()
		
	
	# Check for button presses here
	# Is game still running? And is debounce active?
	if(!game_timer.is_stopped() and next_timer.is_stopped() and !paused):
		var current_button_index = button_combinations[current_index]
		var button_combo = constants.BUTTON_COMBOS[current_button_index]
		
		# Since there are multiple buttons pressed at once, 
		# we keep track of their state here
		# TODO: move this up somehow - so we can use a timer
		# and give user an extra split second or something?
		var presses = []
		for button_index in len(button_combo):
			var button = button_combo[button_index]
			# Check for input
			if Input.is_action_just_pressed(button):
				print("Pressed " + button)
				presses.push_back(true)
				# Start debounce
				#next_timer.start(2)
			else:
				presses.push_back(false)
				
		
		# Did they press all buttons?
		var complete = true
		for button_index in len(button_combo):
			if !presses[button_index]:
				complete = false
		
		# Success!
		if complete:
			# Go to next button or stop at max
			if current_index + 1 == len(button_combinations):
				complete_game()
			if current_index < len(button_combinations) - 1:
				# Go to the next combo
				current_index += 1
				# Move customers
				print("Starting exit animation")
				exit_animation_state_animating = true
				$"../ExitAnimation".start(EXIT_ANIMATION_ROTATE_TIME)
				
				# Spawn a new customer if we need one
				# -3 for 3 slots, - 1 to account for arrays
				if current_index < len(button_combinations) - 4:
					print("new customer")
					var robot = create_customer()
					robot.position = NEW_POSITION
					
					
				
func start_game():
	# Hydrate game with new button combos
	generate_combos()
	
	# Load initial models
	load_initial_models()
	
	# Start game timer
	game_timer.start(DEFAULT_GAME_TIME)
	
func generate_combos():
	var max_random = len(constants.BUTTON_COMBOS) - 1
	button_combinations = []
	# Generate 10 combos
	for index in 10:
		var random_index = rand.randf_range(0, max_random)
		button_combinations.push_back(random_index)
	
func complete_game():
	completed = true
	# TODO: Save time here for scoreboards/rewards
	game_timer.stop()
	
	# Show win UI
	$"../MiniGameWinScreen".visible = true

func pause_game():
	print("Pausing game")
	
	# Pause game timer
	game_timer.paused = true
	
	# Show pause UI
	$"../QuickPause".visible = true

func unpause_game():
	print("Unpausing game")
	# Pause game timer
	game_timer.paused = false

	# Hide Pause UI
	$"../QuickPause".visible = false
	
func restart_game():
	print("Restarting game")
	
	# Reset state
	completed = false
	current_index = 0
	
	# Hide win screen
	$"../MiniGameWinScreen".visible = false
	
	# Start game again
	start_game()
	
func create_customer():
	# Obtain the resource now that we need it
	ResourceLoader.load_threaded_request(ROBOT_MODEL_PATH)
	var robot_scene = ResourceLoader.load_threaded_get(ROBOT_MODEL_PATH)
	# Instantiate the enemy scene and add it to the current scene
	var robot = robot_scene.instantiate()
	$"../Customers".add_child(robot)
	return robot

func load_initial_models():
	for initial_position in INITIAL_POSITIONS:
		var robot = create_customer()
		robot.position = initial_position
