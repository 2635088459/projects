
class_name DurativeUndeathCommand
extends DurativeAnimationCommand

func execute(character:Character) -> Command.Status:
	 # Check if the character is Player type
	if character is Player:
		 # Call resurrect() on player which handles:
		# - Resetting player state
		# - Playing resurrection animation
		# - Triggering sound effects/callbacks
		# - Restoring health
		character.resurrect()  # This method handles everything: state, animation, and callback
		return Status.DONE
		
	return _manage_durative_animation_command(character, "summon")
