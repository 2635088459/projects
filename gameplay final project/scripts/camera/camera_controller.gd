class_name CameraController
extends Camera2D

# Adjust this path to match your scene structure
@onready var player: Player = $"../Punk_Player"

func _ready() -> void:
	if player:
		global_position = player.global_position

func _process(_delta: float) -> void:
	if player:
		global_position = player.global_position
