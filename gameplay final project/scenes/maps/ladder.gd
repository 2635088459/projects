extends Area2D

func _ready():
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		body_entered.connect(_on_body_entered)
	if not is_connected("body_exited", Callable(self, "_on_body_exited")):
		body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("tell_them_who_you_are"):
		# Update the path to match your scene structure
		var player = get_node("/root/World/Punk_Player")
		# Alternative method using the body directly
		if player:
			player.ladder_on = true

func _on_body_exited(body: Node2D) -> void:
	if body.has_method("tell_them_who_you_are"):
		# Update the path to match your scene structure
		var player = get_node("/root/World/Punk_Player")
		if player:
			player.ladder_on = false
