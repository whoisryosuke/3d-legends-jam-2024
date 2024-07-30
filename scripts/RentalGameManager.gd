extends Node

@onready var timer = $"../GameTimer"
@onready var timer_text = $"../MiniGameRentalUI/%TimerText"

# Called when the node enters the scene tree for the first time.
func _ready():
	# Start the game timer
	# TODO: Delay to a 1...2..3 countdown
	timer.start(60)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Update timer text UI
	timer_text.text = str(int(timer.time_left))
