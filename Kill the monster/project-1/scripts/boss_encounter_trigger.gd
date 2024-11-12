class_name BossEncounterTrigger
extends Area2D

@export var camera_location:Node2D
@onready var cutscene_manager = get_node("/root/World/CutsceneManager")  # Changed from %CutsceneManager

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
		
	# Position the camera for the boss fight
	%MainCamera.subject = camera_location
	
	body.command_callback("engage")
	
	
	# Start the cutscene through the manager
	cutscene_manager.start_cutscene()

	# cutscene_manager.end_cutscene()
	# Remove this trigger node
	queue_free()
