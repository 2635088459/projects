extends Area2D
class_name EnemyDogBullet

@export var damage: int

var dog_facing: bool
var direction: Vector2
var speed: float = 500
var player: CharacterBody2D
var enemy_dog: Node
var player_function: Node

@onready var timer: Timer = $Timer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D



func _ready() -> void:
	player_function = get_node("/root/World/Punk_Player")
	player = player_function.tell_them_who_you_are()
	enemy_dog = get_parent()
	dog_facing = enemy_dog.sprite_facing
	if dog_facing == true:
		direction = Vector2.LEFT
	else:
		direction = Vector2.RIGHT
	direction = (player.global_position - global_position).normalized()
	rotation = direction.angle()
	$Timer.start()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	if direction == Vector2.LEFT:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
		


func _on_body_entered(body: Node2D) -> void:
	if body == player:
		animated_sprite.play("hit")
		speed = 0
		signals.player_take_damage.emit(damage)
	queue_free()


func _on_timer_timeout() -> void:
	queue_free()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "hit":
		queue_free()
