class_name Player
extends Character

@export var health:int = 100

var _damaged:bool = false
var _dead:bool = false
var cmd_list : Array[Command]
var jump_count:int = 0 # check the number of jumps

@onready var animation_tree:AnimationTree = $AnimationTree

func _ready():
	animation_tree.active = true
	bind_player_input_commands()
	command_callback("undeath")

func _physics_process(delta: float):
	if _dead:
		return
	if len(cmd_list)>0:
		var command_status:Command.Status = cmd_list.front().execute(self)
		if Command.Status.DONE == command_status:
			cmd_list.pop_front()
	else:
		animation_player.play("idle")
	
	var move_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	
	# add the gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jumping through JumpCommand
	if Input.is_action_just_pressed("jump"):
		up_cmd.execute(self)
		
	if Input.is_action_just_pressed("attack"):
		fire1.execute(self)
	
	if move_input > 0.1:
		right_cmd.execute(self)
	elif move_input < -0.1:
		left_cmd.execute(self)
	else:
		idle.execute(self)
	
	super(delta)
	
	_manage_animation_tree_state()
	if is_on_floor():
		jump_count = 0

func take_damage(damage:int) -> void:
	health -= damage
	_damaged = true
	if 0 >= health:
		_play($Audio/defeat)
		_dead = true
		animation_tree.active = false
		animation_player.play("death")
	else:
		_play($Audio/hurt)

func _manage_animation_tree_state() -> void:
	if !is_zero_approx(velocity.x):
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
	
	#toggles
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

func bind_player_input_commands():
	right_cmd = MoveRightCommand.new()
	left_cmd = MoveLeftCommand.new()
	up_cmd = JumpCommand.new()
	fire1 = AttackCommand.new()
	idle = IdleCommand.new()

func unbind_player_input_commands():
	right_cmd = Command.new()
	left_cmd = Command.new()
	up_cmd = Command.new()
	fire1 = Command.new()
	idle = Command.new()

func resurrect() -> void:
	_dead = false
	health = 100
	animation_tree.active = true
	var sm:AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]
	command_callback("undeath")
	sm.travel("summon")

func command_callback(cmd_name:String) -> void:
	if "attack" == cmd_name:
		_play($Audio/attack)
		
	if "jump" == cmd_name:
		_play($Audio/jump)
		
	if "engage" == cmd_name:
		_play($Audio/engage)
		
	if "undeath" == cmd_name:
		_play($Audio/undeath)

func _play(player:AudioStreamPlayer2D) -> void:
	if !player.playing:
		player.play()
