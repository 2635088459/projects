class_name DamageText
extends Node2D

@export var damage:float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Label.text = "-" + str(int(damage))
	var random_offset = Vector2(
		randf_range(-50, 50),  # Random x offset
		randf_range(-50, 50)   # Random y offset
	)
	
	# Create a tween to move the node to the random position
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", position + random_offset, 0.5)  # Tween over 0.5 seconds
	
	await get_tree().create_timer(0.5).timeout
	
	var tween2 = get_tree().create_tween()
	# Fade out and queue_free after animation
	tween2.tween_property($Label, "modulate", Color(1, 1, 1, 0), 0.3)  # Fade out over 0.3 seconds
	tween2.finished.connect(queue_free)  # Free the node when the tween finishes
