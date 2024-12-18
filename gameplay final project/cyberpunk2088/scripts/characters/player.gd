class_name Player
extends Character 

var cmd_list : Array[Command]
var _damaged:bool = false
var _dead:bool = false
var attack_cooldown:float
var cooldown_elapsed:float
var cooldown_elapsed2:float
var jump_amount:int
var first_time:bool = true
var player: CharacterBody2D = self
var damage_text = preload("res://scenes/attacks/player_damage_text.tscn")
var teleport_effect = preload("res://scenes/interactables/teleport.tscn")
var returning:bool = false
var return_time:float = 1.0
var ladder_on = false
var _climbing = false


@onready var animation_tree:AnimationTree = $AnimationTree_Hand
@onready var weapon:Weapon = $Weapon
@onready var state_machine:AnimationNodeStateMachinePlayback = $AnimationTree_Hand.get("parameters/playback")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _ready():
	jump_velocity = DEFAULT_JUMP_VELOCITY - Stats.upgrades["Jump Power"]*25
	movement_speed = DEFAULT_MOVE_VELOCITY + Stats.upgrades["Movement Speed"]*20
	attack_cooldown = 0.75 - 0.05 * Stats.upgrades["Attack Speed"]
	
	animation_tree.active = true
	signals.player_take_damage.connect(take_damage)
	unbind_player_input_commands()
	
func _physics_process(delta: float):
	if _dead:
		return
		
	if Input.is_action_just_pressed("tp_cheat"):
		global_position = get_global_mouse_position()
		
	# Process climb
	if ladder_on and Input.is_action_pressed("jump"):
		_climbing = true
		velocity.y = -movement_speed
	else:
		_climbing = false
		
	# Process return
	if Input.is_action_pressed("return") and not returning:
		var tp = teleport_effect.instantiate()
		add_child(tp)
		tp.global_position = global_position
		returning = true
	
	if returning and not Input.is_action_pressed("return"):
		# cancel teleport
		if (find_child("Teleport", true, false)):
			find_child("Teleport", true, false).queue_free()
		returning = false
	
	if returning and return_time > 0:
		return_time -= delta
		if return_time <= 0:
			if (find_child("Teleport", true, false)):
				find_child("Teleport", true, false).queue_free()
			global_position = get_tree().current_scene.current_map.find_child("PlayerSpawn").global_position
	else:
		return_time = 1.0
		returning = false
		
	# Process ranged attack
	if Input.is_action_pressed("ranged_attack") and cooldown_elapsed >= attack_cooldown:
		fire1.execute(self)
		cooldown_elapsed = 0
	cooldown_elapsed += delta
	
	# Process multi_jump
	if is_on_floor():
		jump_amount = 0
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			up_cmd.execute(self)
		elif jump_amount <= Stats.upgrades["Double Jump"] && velocity.y >= 0:
			jump_amount += 1
			# Move to doublejump animation
			state_machine.start("multi_jump", true)
			up_cmd.execute(self)
			
	# Process horizontal move
	var move_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if move_input > 0.1:
		right_cmd.execute(self)
	elif move_input < -0.1:
		left_cmd.execute(self)
	else:
		idle.execute(self)
		
	# melee attack
	if Input.is_action_just_pressed("melee_attack") and cooldown_elapsed2 >= attack_cooldown*1.6:
		cooldown_elapsed2 = 0
		fire2.execute(self)
	cooldown_elapsed2 += delta
		
		# Let character face the gun!
	if weapon.scale.x == 1:
		animated_sprite_2d.flip_h = false
		change_facing(Character.Facing.RIGHT)
	elif weapon.scale.x == -1:
		animated_sprite_2d.flip_h = true
		change_facing(Character.Facing.LEFT)

	# Process attack
	_manage_animation_tree_state()
	super(delta)
	
func take_damage(damage:int) -> void:
	if _dead:
		return
	var dmg_text = damage_text.instantiate()
	dmg_text.damage = damage
	dmg_text.global_position = global_position
	get_tree().current_scene.add_child(dmg_text)
	_damaged = true
	Stats.health -= damage
	if Stats.health <= 0:
		_dead = true
		animation_tree.active = false
		animation_player.play("death")
	else:
		_play($Audio/Hurt)

func ranged_attack():
	weapon.fire()
	
func _manage_animation_tree_state() -> void:
	if !is_zero_approx(velocity.x):
		
		if (velocity.x > 0) == (facing == Facing.RIGHT):
			# This is a ugly solution but I can't find better
			animation_tree.get_tree_root().get_node("run").play_mode = AnimationNodeAnimation.PlayMode.PLAY_MODE_FORWARD
		else:
			animation_tree.get_tree_root().get_node("run").play_mode = AnimationNodeAnimation.PlayMode.PLAY_MODE_BACKWARD
			
		animation_tree["parameters/conditions/idle"] = false
		animation_tree["parameters/conditions/moving"] = true
	else:
		animation_tree["parameters/conditions/idle"] = true
		animation_tree["parameters/conditions/moving"] = false
	
	if is_on_floor():
		animation_tree["parameters/conditions/jumping"] = false
		animation_tree["parameters/conditions/on_floor"] = true
	else:
		animation_tree["parameters/conditions/jumping"] = true
		animation_tree["parameters/conditions/on_floor"] = false
	
	if attacking:
		animation_tree["parameters/conditions/attacking"] = true
		attacking = false
	else:
		animation_tree["parameters/conditions/attacking"] = false

	if _damaged:
		animation_tree["parameters/conditions/damaged"] = true
		_damaged = false
	else:
		animation_tree["parameters/conditions/damaged"] = false
		
	if _climbing:
		animation_tree["parameters/conditions/climbing"] = true
		animation_tree["parameters/conditions/multi_jump"] = false
	else:
		animation_tree["parameters/conditions/climbing"] = false
		if ladder_on:
			animation_tree["parameters/conditions/multi_jump"] = false
		else:
			animation_tree["parameters/conditions/multi_jump"] = true

func bind_player_input_commands():
	right_cmd = MoveRightCommand.new()
	left_cmd = MoveLeftCommand.new()
	up_cmd = JumpCommand.new()
	fire1 = RangedAttackCommand.new()
	fire2 = MeleeAttackCommand.new()
	idle = IdleCommand.new()
	weapon.rotating = true

func unbind_player_input_commands():
	right_cmd = Command.new()
	left_cmd = Command.new()
	up_cmd = Command.new()
	fire1 = Command.new()
	fire2 = Command.new()
	idle = Command.new()
	weapon.rotating = false

func player_reset(): 
	_damaged = false
	_dead = false
	first_time = true 
	animation_tree.active = true
	jump_velocity = DEFAULT_JUMP_VELOCITY - Stats.upgrades["Jump Power"]*25
	movement_speed = DEFAULT_MOVE_VELOCITY + Stats.upgrades["Movement Speed"]*20
	attack_cooldown = 0.75 - 0.05 * Stats.upgrades["Attack Speed"]
	
func tell_them_who_you_are():
	return player
	
func _play(player:AudioStreamPlayer) -> void:
	if !player.playing:
		player.play()
