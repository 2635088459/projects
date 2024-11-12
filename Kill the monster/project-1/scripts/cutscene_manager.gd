# cutscene_manager.gd
class_name CutsceneManager
extends Node
# stage three main section
# Node references using unique names in the scene tree
@onready var _player := %Player
@onready var _follower := %Follower
@onready var _boss_1 := %Boss
@onready var _boss_2 := %Boss2

# Manager and command references
var boss_fight_manager: Boss2FightManager
var moveLeft := MoveLeftCommand.new()
var cutscene_active := false

func start_cutscene() -> void:
	# Activate cutscene state
	cutscene_active = true
	
	# Initialize characters to idle state
	_player.idle.execute(_player)
	var idle_command = IdleCommand.new()
	idle_command.execute(_follower)

	# Disable player controls during cutscene
	_player.unbind_player_input_commands()

	# Set up player's command sequence
	var player_commands: Array[Command] = []
	# Initial actions
	player_commands.append(DurativeAttackCommand.new())
	player_commands.append(DurativeIdleCommand.new(5.5))
	player_commands.append(DurativeJumpCommand.new(0))
	# First dialogue sequence
	player_commands.append(DurativeDialogueCommand.new("Yuusha: Luna, You sure? I did not see the kid. By the way, Did you hear anything?", 3.5))
	player_commands.append(DurativeJumpCommand.new(0))
	# Kid's cry for help
	player_commands.append(DurativeDialogueCommand.new("Kid: Help!!", 2.3))
	player_commands.append(DurativeIdleCommand.new(23.0))
	# Revival sequence
	player_commands.append(DurativeUndeathCommand.new())
	player_commands.append(DurativeIdleCommand.new(2.0))
	player_commands.append(DurativeMoveRightCommand.new(0.8))
	# Final dialogue
	player_commands.append(DurativeDialogueCommand.new("Yuusha: Thank you，Luna！Go back to the Town and Tell People We found kid! I will kill this monster!", 3.0))
	
	_player.cmd_list = player_commands

	# Set up follower's (Luna's) command sequence
	var follower_commands: Array[Command] = []
	# Initial dialogue and movement
	follower_commands.append(DurativeIdleCommand.new(1.0))
	follower_commands.append(DurativeJumpCommand.new(0))
	follower_commands.append(DurativeDialogueCommand.new("Luna: Yuusha, This is the place that the elder told me. We have to find the child who was caught by the demo", 4.4))
	follower_commands.append(DurativeIdleCommand.new(7.5))
	follower_commands.append(DurativeDialogueCommand.new("Luna: The Kid！ Let me get inside to see if I can bring him out", 4.0))
	# Movement and sensing sequence
	follower_commands.append(DurativeMoveRightCommand.new(2.5))
	follower_commands.append(DurativeDialogueCommand.new("Luna:I sense a dark power...", 4.0))
	follower_commands.append(DurativeIdleCommand.new(1.0))
	# Reaction to danger
	follower_commands.append(DurativeFaceLEFTDirectionCommand.new(Character.Facing.LEFT))
	follower_commands.append(DurativeIdleCommand.new(1.0))
	follower_commands.append(DurativeDialogueCommand.new("Luna: No! Yuusha!", 2.0))
	follower_commands.append(DurativeIdleCommand.new(2.0))
	# Healing sequence
	follower_commands.append(DurativeMoveLeftCommand.new(2.3))
	follower_commands.append(DurativeIdleCommand.new(1.5))
	follower_commands.append(DurativeFaceRightDirectionCommand.new(Character.Facing.RIGHT))
	follower_commands.append(DurativeDialogueCommand.new("Luna: Let me heal you!", 1.5))
	follower_commands.append(DurativeIdleCommand.new(4.5))
	follower_commands.append(DurativeMoveLeftCommand.new(2.3))
	
	_follower.cmd_list = follower_commands

	# Set up Boss1's appearance and actions
	var boss_commands: Array[Command] = []
	await get_tree().create_timer(24.0).timeout  # Wait for dramatic timing
	_boss_1.sprite.visible = true
	boss_commands.append(SummonCommand.new())
	boss_commands.append(DurativeAttackCommand.new())
	boss_commands.append(DurativeDismissCommand.new())
	boss_commands.append(DurativeMoveLeftCommand.new(1.0))
	_boss_1.cmd_list = boss_commands

	# Set up Boss2's appearance and actions
	var boss_commands_2: Array[Command] = []
	await get_tree().create_timer(8.0).timeout  # Additional timing for second boss
	_boss_2.sprite.visible = true
	# Boss2 entrance sequence
	boss_commands_2.append(SummonCommand.new())
	boss_commands_2.append(DurativeMoveLeftCommand.new(0.4))
	boss_commands_2.append(DurativeIdleCommand.new(2.0))
	boss_commands_2.append(DurativeJumpCommand.new(0))
	boss_commands_2.append(DurativeJumpCommand.new(0))
	boss_commands_2.append(DurativeIdleCommand.new(2.0))
	# Boss2 dialogue
	boss_commands_2.append(DurativeDialogueCommand.new("Demo: MORTALS DARE TO ENTER MY DOMAIN!", 2.0))
	boss_commands_2.append(DurativeIdleCommand.new(0.2))
	boss_commands_2.append(DurativeDialogueCommand.new("Demo: You Will Die Here!", 2.0))
	_boss_2.cmd_list = boss_commands_2

func check_and_end_cutscene() -> void:
	# Don't check if cutscene isn't active
	if not cutscene_active:
		return
	
	# Check if all characters have completed their command lists
	var lists_empty = _player.cmd_list.is_empty() and _follower.cmd_list.is_empty() and _boss_1.cmd_list.is_empty() and _boss_2.cmd_list.is_empty()
	
	# If all commands are complete, end the cutscene
	if lists_empty:
		end_cutscene()

func end_cutscene() -> void:
	# Re-enable player controls
	_player.bind_player_input_commands()
	cutscene_active = false
	
	# Start the boss fight sequence
	var boss_fight_manager = Boss2FightManager.new(_boss_2, _player)
	boss_fight_manager.name = "Boss2FightManager"
	add_child(boss_fight_manager)
	boss_fight_manager.start_fight()

func _process(_delta: float) -> void:
	# Continuously check for cutscene completion
	if cutscene_active:
		check_and_end_cutscene()
