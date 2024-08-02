extends Node

@onready var game_timer = $"../GameTimer"
@onready var next_timer = $"../NextTimer"
@onready var countdown_timer = $"../CountdownTimer"
@onready var fail_timer = $"../FailTimer"
@onready var timer_text = $"../CanvasLayer/MiniGameRentalUI/%TimerText"
@onready var dialogue_text = $"../CanvasLayer/MiniGameRentalUI/%DialogueText"
@onready var dialogue_container = $"../CanvasLayer/MiniGameRentalUI/%DialogueContainer"
@onready var remaining_counter_text = $"../CanvasLayer/MiniGameRentalUI/%RemainingCounter"
const ROBOT_MODEL_PATH = "res://scenes/customer.tscn"
var rand = RandomNumberGenerator.new()

# Constants
const constants = preload("res://scripts/constants.gd")
const COUNTDOWN_TIME = 3
const DEFAULT_GAME_TIME = 60
const FAIL_TIME = 1
const END_POSITION = Vector3(-0.77, 0.0, -6.16)
const INITIAL_POSITIONS = [
	Vector3(1.9, 0.0, -6.16),
	Vector3(3.9, 0.0, -6.36),
	Vector3(7.1, 0.0, -6.26),
]
const NEW_POSITION = Vector3(11.1, 0.0, -6.26)
const INITIAL_ROTATIONS = [
	0.0,
	0.0,
	90.0,
	157.0,
	90.0,
]
const EXIT_ANIMATION_ROTATE_TIME = 0.5
const EXIT_ANIMATION_WALK_TIME = 1
const EXIT_ANIMATION_STATES = [
	"ROTATE",
	"WALK",
	"ROTATE_BACK",
]

# Game State
var intro_playing = false
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
	var current_time_text = str(int(game_timer.time_left))
	if len(current_time_text) < 2:
		current_time_text = "0" + current_time_text
	timer_text.text = "00:00:" + current_time_text
	
	# Update dialogue (aka the required button sequence)
	var current_button_index = button_combinations[current_index]
	var current_game = constants.RECIPES[current_button_index]
	var current_button = constants.BUTTON_COMBOS[current_button_index]
	var current_button_text = ""
	for text in current_button:
		current_button_text += text + " "
		
		
	# Hide Dialogue if user failed
	if !fail_timer.is_stopped():
		dialogue_text.text = "That's not right..."
	else:
		dialogue_text.text = current_game
	
	# Game over
	if playing and game_timer.is_stopped():
		print("Game over!")
		
	
	## Animations
	# Intro animation
	if !countdown_timer.is_stopped():
		intro_countdown()
	if countdown_timer.is_stopped() and intro_playing:
		intro_playing = false
		end_countdown()
	# Exit animation
	if exit_animation_state_animating:
		handle_exit_animation()

func intro_countdown():
	intro_playing = true
	var countdown_time = countdown_timer.time_left
	
	# Update text
	var countdown_text = str(int(countdown_time))
	if countdown_text == "0":
		countdown_text = "Go!"
	$"../MiniGameCountdown/%CountdownText".text = countdown_text
	
func end_countdown():
	$"../MiniGameCountdown".visible = false
	start_game_timer()

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
			"ROTATE_BACK":
				var time_interpolation = 1.0 - (timer.time_left / EXIT_ANIMATION_ROTATE_TIME)
				for customer_index in len(customers):
					if customer_index != 0:
						var customer = customers[customer_index]
						customer.rotation.y = lerp(customer.rotation.y, INITIAL_ROTATIONS[customer_index], time_interpolation)
	else:
		print("ANIMATION TIMER DONE!")
		# Move to next state and restart timer if needed
		if exit_animation_state_index < len(EXIT_ANIMATION_STATES) - 1:
			exit_animation_state_index += 1
			match EXIT_ANIMATION_STATES[exit_animation_state_index]:
				"WALK":
					print("Triggering walk animation")
					$"../ExitAnimation".start(EXIT_ANIMATION_WALK_TIME)
					
				"ROTATE_BACK":
					print("Triggering rotate back animation")
					$"../ExitAnimation".start(EXIT_ANIMATION_ROTATE_TIME)
					var customers = $"../Customers".get_children()
					customers[0].get_node("./VFXAnimation").play("disappear")
		else:
			print("Animation done!")
			# Done animating - reset state
			exit_animation_state_animating = false
			exit_animation_state_index = 0
			# Get rid of the first child
			var customers = $"../Customers".get_children()
			customers[0].queue_free()
			# Play game animation
			play_vfx_animation()
			
			# Show dialogue UI
			dialogue_container.visible = true
	

func _input(event):
	# Restart game
	if(game_timer.is_stopped() and Input.is_action_just_pressed("Triangle")):
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
	if(!game_timer.is_stopped() and next_timer.is_stopped() and !paused and !exit_animation_state_animating and fail_timer.is_stopped()):
		var current_button_index = button_combinations[current_index]
		var button_combo = constants.BUTTON_COMBOS[current_button_index]
		
		# Check if any input was pressed
		if Input.is_anything_pressed():
			# Check if it was a button we need
			
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
					
					# Hide dialogue UI
					dialogue_container.visible = false
					
					# Move customers
					print("Starting exit animation")
					exit_animation_state_animating = true
					$"../ExitAnimation".start(EXIT_ANIMATION_ROTATE_TIME)
					
					# Spawn a new customer if we need one
					# -3 for 3 slots, - 1 to account for arrays
					if current_index < len(button_combinations) - 2:
						print("new customer")
						var robot = create_customer()
						robot.position = NEW_POSITION
			else:
				print("Failed!")
				fail_timer.start(FAIL_TIME)
					
					
func play_vfx_animation():
	var customers = $"../Customers".get_children()
	customers[0].get_node("./VFXAnimation").play("appear")
	
				
			
func start_game():
	# Hydrate game with new button combos
	generate_combos()
	
	# Load initial models
	load_initial_models()
	
	# Start intro timer
	countdown_timer.start(COUNTDOWN_TIME);
	
func start_game_timer():
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
	play_vfx_animation()		
