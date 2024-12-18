class_name Enemy
extends Character 

@export var health:int = 100 + Stats.level * 50
@export var max_health:int = 100 + Stats.level * 50
@export var coin_reward:int = 20 + Stats.level * 10
@export var damage: int = 10

@export var player: CharacterBody2D



var cmd_list : Array[Command]
var _damaged:bool = false
var _dead:bool = false
var damage_text = preload("res://scenes/attacks/damage_text.tscn")
var coin_drop = preload("res://scenes/interactables/coin_drop.tscn")
var health_drop = preload("res://scenes/interactables/health_drop.tscn")

var player_function: Node

@onready var animation_tree:AnimationTree = $AnimationTree
@onready var health_node:Control = $Health
@onready var health_bar:ProgressBar = $Health/ProgressBar


enum States{
	WANDER,
	CHASE
}

var last_hit:float = 0.0

func _ready():
	animation_tree.active = true
	health_node.visible = false
	health_bar.max_value = max_health
	health_bar.value = health
	
	player_function = get_node("/root/World/Punk_Player")
	player = player_function.tell_them_who_you_are()
	bind_commands()
	

func _physics_process(delta: float):
	#handle_gravity(delta)
	#handle_movement(delta)
	#change_direction()
	#look_for_player()
	#
	health_bar.value = health
	last_hit += delta
	if last_hit > 3:
		health_node.visible = false
	super(delta)


func spawn_dmg_text(dmg:int):
	var dmg_text = damage_text.instantiate()
	dmg_text.damage = dmg
	dmg_text.global_position = global_position
	get_tree().current_scene.add_child(dmg_text)


func spawn_coin():
	var coin = coin_drop.instantiate()
	coin.coin_reward = coin_reward
	coin.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", coin)
	
	
func spawn_health():
	var hp = health_drop.instantiate()
	hp.health_reward = randi_range(5,25)
	hp.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", hp)
	
	
func boss_bonus():
	for i in range(4):
		spawn_coin()
		spawn_health()
	

func take_damage(dmg:int) -> void:
	if _dead:
		return
	spawn_dmg_text(dmg)
	last_hit = 0
	health_node.visible = true
	health -= dmg
	if health <= 0 and not _dead:
		health_node.visible = false
		_dead = true
		spawn_coin()
		# 20% chance to spawn health
		if randi_range(1,5) == 1:
			spawn_health()
		if self is BossSlime: # await death animation
			get_tree().current_scene.boss_dead = true
			boss_bonus()
			await get_tree().create_timer(2).timeout
		if self is BossEx1: # await death animation
			boss_bonus()
			get_tree().current_scene.boss_dead = true
			await get_tree().create_timer(3.5).timeout
		if self is EnemySamurai:
			await get_tree().create_timer(2).timeout
		if self is EnemySlime:
			await get_tree().create_timer(2).timeout
		queue_free()
	


func bind_commands():
	right_cmd = MoveRightCommand.new()
	left_cmd = MoveLeftCommand.new()
	up_cmd = JumpCommand.new()
	# fire1 = RangedAttackCommand.new()
	idle = IdleCommand.new()
	
