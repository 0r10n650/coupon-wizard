extends Node3D

var audio_player: AudioStreamPlayer3D

func _ready() -> void:
	audio_player = $BackgroundMusic
	audio_player.finished.connect(func(): audio_player.play())
