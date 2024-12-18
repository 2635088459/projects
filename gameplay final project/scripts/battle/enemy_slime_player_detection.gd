extends Area2D

@onready var enemy_slime: EnemySlime = $".."

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_play($"../Audio/Find_player")
		enemy_slime.start_moving = true
		queue_free()

func _play(player:AudioStreamPlayer2D) -> void:
	if !player.playing:
		player.play()
