class_name FollowerController
extends Character

# Reference to the character this follower should follow
var target: Character

# List of commands to be executed by the follower
var cmd_list: Array[Command]

# Reference to player node to check player's state
@onready var player: Player = %Player

func _ready():
	# Set the target to be the Player node
	# Using 'as Player' ensures type safety
	target = %Player as Player
	
	# Set movement properties
	movement_speed = 250  # Player speed is typically 300
	jump_velocity = -500  # Slightly lower jump than player
	
	# Initialize with a follow command
	# This ensures the follower starts following immediately when game begins
	cmd_list.append(FollowCommand.new())

func _physics_process(delta: float) -> void:
	# Process commands if there are any in the list
	if len(cmd_list) > 0:
	   
		var command_status: Command.Status = cmd_list.front().execute(self)
		
		# If the command is done, remove it from the list
		if Command.Status.DONE == command_status:
			cmd_list.pop_front()
			
			# 1. The command list is empty (no other commands to execute)
			# 2. Player is not in a cutscene (checked by seeing if player has normal movement commands)
			# The 'is MoveRightCommand' check helps determine if player has normal control
			if cmd_list.is_empty() and player.right_cmd is MoveRightCommand:
				cmd_list.append(FollowCommand.new())
				animation_player.play("idle")
	super(delta)
