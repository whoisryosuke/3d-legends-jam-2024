extends Control

func _input(event):
	if Input.is_anything_pressed():
		%Button.emit_signal("pressed")
