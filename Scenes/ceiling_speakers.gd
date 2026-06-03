extends Node3D

func _ready():
	play_all_speakers()

func play_all_speakers():
	# Iterate through all AudioStreamPlayer3D children and play them on the exact same frame
	for child in get_children():
		if child is AudioStreamPlayer3D:
			child.play()
