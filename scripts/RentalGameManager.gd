extends Node

@onready var game_timer = $"../GameTimer"
@onready var next_timer = $"../NextTimer"
@onready var timer_text = $"../MiniGameRentalUI/%TimerText"
@onready var dialogue_text = $"../MiniGameRentalUI/%DialogueText"
@onready var remaining_counter_text = $"../MiniGameRentalUI/%RemainingCounter"
var rand = RandomNumberGenerator.new()

const DEFAULT_GAME_TIME = 60
var playing = false
var paused = false
var completed = false
var current_index = 0
const constants = preload("res://scripts/constants.gd")
var button_combinations = [
	3,
	4,
]

# Called when the node enters the scene tree for the first time.
func _ready():
	# Start the game timer
	# TODO: Delay to a 1...2..3 countdown
	start_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
		
		if complete:
			# Go to next button or stop at max
			if current_index + 1 == len(button_combinations):
				complete_game()
			if current_index < len(button_combinations) - 1:
				current_index += 1
				
func start_game():
	# Hydrate game with new button combos
	generate_combos()
	
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
