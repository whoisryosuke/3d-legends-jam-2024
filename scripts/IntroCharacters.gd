extends Node3D

func run_all():
	print("Making characters run")
	for child in self.get_children():
		if child.has_method("run"):
			print("Run dude!")
			child.run()
