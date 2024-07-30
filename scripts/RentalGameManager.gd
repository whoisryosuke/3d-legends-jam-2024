extends Node

@onready var game_timer = $"../GameTimer"
@onready var next_timer = $"../NextTimer"
@onready var timer_text = $"../MiniGameRentalUI/%TimerText"
@onready var dialogue_text = $"../MiniGameRentalUI/%DialogueText"

const DEFAULT_GAME_TIME = 60
var playing = false
var paused = false
var completed = false
var current_index = 0
const BUTTONS = [
	"Cross",
	"Circle",
	"Triangle",
	"Square",
	"L1",
	"L2",
	"R1",
	"R2",
	"DPad Up",
	"DPad Down",
	"DPad Left",
	"DPad Right",
]
var button_combinations = [
	["Square"],
	["Triangle"],
]

# Called when the node enters the scene tree for the first time.
func _ready():
	# Start the game timer
	# TODO: Delay to a 1...2..3 countdown
	start_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Update timer text UI
	timer_text.text = str(int(game_timer.time_left))
	
	# Update dialogue (aka the required button sequence)
	var current_button = button_combinations[current_index][0]
	dialogue_text.text = current_button

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
		var current_button = button_combinations[current_index][0]
		# Check for input
		if Input.is_action_just_pressed(current_button):
			print("Pressed " + current_button)
			# Start debounce
			#next_timer.start(2)
			# Go to next button or stop at max
			if current_index + 1 == len(button_combinations):
				complete_game()
			if current_index < len(button_combinations) - 1:
				current_index += 1
				print("Button # " + str(current_index))
				
func start_game():
	game_timer.start(DEFAULT_GAME_TIME)
	
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
