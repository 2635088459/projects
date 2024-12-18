extends Area2D

@onready var boss_ex_1: BossEx1 = $".."

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		boss_ex_1.boss_fight_start()
		queue_free()
