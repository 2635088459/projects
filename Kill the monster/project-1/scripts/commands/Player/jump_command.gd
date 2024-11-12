class_name JumpCommand
extends Command

func execute(character: Character) -> Status:
	# Check if the character is specifically a Player
	if character is Player:
		var player := character as Player
		
		# Case 1: Player is on the floor (first jump)
		if player.is_on_floor():
			# Apply jump velocity with 1.5x multiplier for better jump feel
			player.velocity.y = player.jump_velocity * 1.5
			# Set jump count to 1 to track first jump
			player.jump_count = 1
			# Set jumping state to true
			player.jumping = true
			
		# Case 2: Player is in air and hasn't used second jump
		elif player.jump_count <= 1:
			# Apply second jump with same velocity
			player.velocity.y = player.jump_velocity * 1.5
			# Increment jump count to prevent more jumps
			player.jump_count += 1
			# Maintain jumping state
			player.jumping = true
		
		
		player.command_callback("jump")
	
	# Command is completed immediately after execution
	return Status.DONE
