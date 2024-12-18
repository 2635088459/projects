class_name EnemyDog
extends Enemy


@export var SPEED: int = 100
@export var CHASE_SPEED: int = 200
@export var ACCELERATION: int = 300


var direction: Vector2
var right_bounds: Vector2
var left_bounds: Vector2
var sprite_facing: bool

var projectile:PackedScene = preload("res://scenes/attacks/emeny_dog_bullet.tscn")


@onready var bullet_timer: Timer = $BulletTimer


func _ready():
	health_node.visible = false
	health_bar.max_value = max_health
	health_bar.value = health
	
	player_function = get_node("/root/World/Punk_Player")
	player = player_function.tell_them_who_you_are()
	bind_commands()


func _physics_process(delta: float):
	if sprite == null:
		return
	
	
	if sprite.flip_h:
		sprite_facing = true
	else:
		sprite_facing = false
	
	change_direction()
	
	if not self.is_on_floor():
		_apply_gravity(delta)
	last_hit += delta
	if last_hit > 3:
		health_node.visible = false
	#_manage_animation_tree_state()
	super(delta)


func take_damage(dmg:int) -> void:
	_play($audio/hurt)
	super(dmg)


func bind_commands():
	right_cmd = MoveRightCommand.new()
	left_cmd = MoveLeftCommand.new()
	up_cmd = JumpCommand.new()
	# fire1 = RangedAttackCommand.new()
	idle = IdleCommand.new()


func change_direction():
	direction = (player.global_position - self.global_position).normalized()
	direction = sign(direction)
	if direction.x == 1:
		sprite.flip_h = false
	else:
		sprite.flip_h = true


func fire() -> void:
	_play($audio/fire)
	var new_projectile = projectile.instantiate() as EnemyDogBullet
	if !sprite.flip_h:
		$ProjectileSpawnRight.add_child(new_projectile)
	else:
		$ProjectileSpawnLeft.add_child(new_projectile)


func _on_hit_box_body_entered(body: Node2D) -> void:
	if body == player:
		attacking = true
		signals.player_take_damage.emit(damage)


func _on_hit_box_body_exited(_body: Node2D) -> void:
	attacking = false


func _on_bullet_timer_timeout() -> void:
	animation_player.play("attack")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		fire()
		animation_player.play("idle")


func dog_facing():
	return sprite_facing
	
func _play(player:AudioStreamPlayer2D) -> void:
	if !player.playing:
		player.play()
