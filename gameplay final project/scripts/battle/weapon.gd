class_name Weapon
extends Node2D

@export var min_angle: float = deg_to_rad(-45)
@export var max_angle: float = deg_to_rad(45)
@export var bullet_group = preload("res://scenes/attacks/bullet_group.tscn")

var rotating = false

@onready var world:World = get_node("/root/World")
@onready var end_point: Node2D = $EndPoint
@onready var start_point: Node2D = $StartPoint
@onready var player: Player = $".."
@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var audio: Node2D = $"../Audio"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player._dead or !rotating:
		return
	
	# Adjust Rotation based on mouse and direction
	var mouse_position = get_global_mouse_position()
	var angle = (mouse_position - global_position).angle()
	if angle < deg_to_rad(90) and angle > deg_to_rad(-90):
		scale.x = 1
		rotation = clamp(angle, min_angle, max_angle)
	else:
		scale.x = -1
		if angle > max_angle - PI and angle < min_angle + PI:
			if angle > 0:
				angle = min_angle + PI
			else:
				angle = max_angle - PI
		rotation = angle - PI
	
func fire():
	_play($"../Audio/GunFire")
	# Measure direction
	var spawn_position = end_point.global_position
	var direction = (end_point.global_position - start_point.global_position).normalized()
	# Create bullet
	var new_bullet_group = bullet_group.instantiate()
	new_bullet_group.velo = direction * new_bullet_group.speed
	new_bullet_group.global_position = spawn_position
	new_bullet_group.scale = Vector2(2,2)
	world.current_map.add_child(new_bullet_group)
	
func _play(player:AudioStreamPlayer) -> void:
	if !player.playing:
		player.play()
	
