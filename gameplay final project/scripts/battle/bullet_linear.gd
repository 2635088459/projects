class_name Bullet_Linear
extends RigidBody2D

var bounce_count: int = 0
var direction:Vector2
@onready var hit_box: HitBox = $HitBox
@export var max_bounces: int = 3
@export var speed: float = 300.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	linear_velocity = direction * speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	linear_velocity = direction * speed

# Hit enemy
func _on_hit_box_area_entered(area: Area2D) -> void:
	queue_free()

# Hit wall
func _on_body_entered(body: Node) -> void:
	var collision_normal = body.get_collision_normal()  # 获取动态法线
	direction = direction.bounce(collision_normal)
	bounce_count += 1
	if bounce_count >= max_bounces:
		queue_free()
