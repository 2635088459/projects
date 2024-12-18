class_name BossSlime
extends Enemy 

@export var SPEED: int = 200
@export var ACCELERATION: int = 100

var boss_slime_fight_start: bool = false
var direction: Vector2
var distance: Vector2
var _death:bool = false
var spawn:float = 3
var enemy_slime = preload("res://scenes/characters/enemy_slime.tscn")

@onready var hit_box_collision_shape: CollisionShape2D = $HitBox/HitBoxCollisionShape
@onready var hurt_box_collision_shape: CollisionShape2D = $HurtBox/HurtBoxCollisionShape
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer

func _ready():
	max_health *= 5
	health = max_health
	
	player_function = get_node("/root/World/Punk_Player")
	player = player_function.tell_them_who_you_are()
	
	hit_box_collision_shape.disabled = true
	
	super()


func _physics_process(delta: float) -> void:
	super(delta)
	if boss_slime_fight_start == false:
		return
	if _death:
		return
	
	_apply_gravity(delta)
	handle_movement(delta)
	change_direction()
	
	
	if _death:
		cmd_list.clear()
		if !animation_player.is_playing():
			sprite.visible = false
			global_position = Vector2(0,0)
		return
	
	if len(cmd_list)>0:
		var command_status:Command.Status = cmd_list.front().execute(self)
		#if command_status == Command.Status.ACTIVE:
		if Command.Status.DONE == command_status:
			cmd_list.pop_front()
	else:
		_manage_animation()
		
	if spawn < 0:
		spawn = randf_range(2, 6)
		var slime = enemy_slime.instantiate()
		get_parent().add_child(slime)
		slime.global_position = global_position
		slime.scale = Vector2(2,2)
		var target = player.global_position
		target.y -= 500
		var direction = (target - slime.global_position).normalized()
		for i in range(100):
			slime.global_position = slime.global_position + direction * 5
			await get_tree().create_timer(0.005).timeout
	else:
		spawn -= delta


func take_damage(dmg:int) -> void:
	super(dmg)
	if 0 >= health:
		_death = true
		velocity = Vector2.ZERO
		animation_player.play("death")


func change_direction() -> void:
	direction = (player.global_position - self.global_position).normalized()
	direction = sign(direction)
	if direction.x == 1:
		sprite.flip_h = true
		collision_shape.position = Vector2(-3, 7)
		hurt_box_collision_shape.position = Vector2(-2, 3)
		hit_box_collision_shape.position = Vector2(26.5, 9.5)
	else:
		sprite.flip_h = false
		collision_shape.position = Vector2(20, 7)
		hurt_box_collision_shape.position = Vector2(20, 3)
		hit_box_collision_shape.position = Vector2(-6.5, 9.5)


func handle_movement(delta: float) -> void:
	velocity = velocity.move_toward(direction * SPEED, ACCELERATION * delta)	
	move_and_slide()


func _manage_animation() -> void:
	if attacking:
		animation_player.play("attack")	
	else:
		animation_player.play("idle")


func boss_fight_start() -> void:
	boss_slime_fight_start = true


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death":
		queue_free()
	if anim_name == "attack":
		attacking = false


func _on_player_detection_body_entered(body: Node2D) -> void:
	if body is Player:
		boss_fight_start()
		attack_timer.start()


func _on_attack_timer_timeout() -> void:
	attacking = true
