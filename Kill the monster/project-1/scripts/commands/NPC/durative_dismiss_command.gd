# durative_dismiss_command.gd
# follow the simialr logical and idea based on orginal durative scripts were provided
class_name DurativeDismissCommand
extends DurativeAnimationCommand

func execute(character: Character) -> Command.Status:
	# Check if this is the first time executing (no timer yet)
	if _timer == null:
		# Play the summon animation in reverse for dismiss effect
		character.animation_player.play_backwards("summon")
		
		
		_timer = Timer.new()
		character.add_child(_timer)  # Add timer as child of character
		_timer.one_shot = true      # Timer will fire only once
		
		# Trigger sound effect or other callbacks
		character.command_callback("summon")
		
		# Only start the timer if the animation has a duration
		# is_zero_approx checks if the length is effectively zero
		if !is_zero_approx(character.animation_player.current_animation_length):
			# Set timer duration to match animation length
			_timer.start(character.animation_player.current_animation_length)
		
		# Return ACTIVE to indicate command is still running
		return Status.ACTIVE
	
	# Check if timer is still running
	if !_timer.is_stopped():
		# Command still executing while timer runs
		return Status.ACTIVE
	else:
		# Timer finished, check if character is a Boss
		if character is Boss:
			# Hide the boss sprite after dismiss animation
			character.sprite.visible = false
		
		return Status.DONE
