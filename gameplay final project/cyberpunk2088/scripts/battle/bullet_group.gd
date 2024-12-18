class_name BulletGroup
extends Node2D

@export var velo: Vector2
@export var speed: float = 200 + Stats.upgrades["Bullet Speed"] * 40
@export var lifespan: float = 2

func _ready():
	update_bullets()

func _physics_process(delta: float) -> void:
	lifespan -= delta
	if lifespan <= 0:
		queue_free()

func update_bullets():
	# Get the current bullet count level
	var max_bullets = clamp(Stats.upgrades["Bullet Count"]+1, 1, 12)
	
	# give bonus 2 bullets at max level
	if max_bullets == 10:
		max_bullets = 12
	
	# Iterate over child nodes
	for i in range(1, get_child_count()+1):
		var bullet = find_child("Bullet"+str(i))
		# Only keep bullets that are within the allowed count
		if i > max_bullets:
			bullet.queue_free()  # Remove extra bullets
		else:
			bullet.velo = velo
			bullet.rotation = velo.angle()
			
