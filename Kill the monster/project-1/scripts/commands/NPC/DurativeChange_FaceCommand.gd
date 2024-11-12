# durative_change_face_command.gd
extends Command
class_name DurativeChangeFaceCommand
# follow and use the simialr logical that orignal script provided as reference 

var facing_direction: Character.Facing  # Direction character should face
var duration: float                    # How long to maintain the facing
var time_elapsed: float = 0.0          # Track how long command has been running
var done: bool = false                 # Track if command has completed its duration

# Initialize the command with direction and duration
func _init(direction: Character.Facing, duration_time: float):
	# Store the target facing direction
	facing_direction = direction
	# Store how long to maintain this facing
	duration = duration_time

func execute(character: Character) -> Status:
	# If command was previously completed, reset and finish
	if done:
		# Reset timing for potential reuse
		time_elapsed = 0.0
		# Reset completion flag
		done = false
		# Command has completed its purpose
		return Status.DONE
		
	# First-time execution (when timer starts)
	if time_elapsed == 0.0:
		# Set character facing based on specified direction
		if facing_direction == Character.Facing.RIGHT:
			# Don't flip sprite for right-facing
			character.sprite.flip_h = false
			# Update character's facing state
			character.change_facing(Character.Facing.RIGHT)
		else:
			# Flip sprite for left-facing
			character.sprite.flip_h = true
			# Update character's facing state
			character.change_facing(Character.Facing.LEFT)
	
	# Update elapsed time using character's process delta
	time_elapsed += character.get_process_delta_time()
	
	# Check if duration has elapsed
	if time_elapsed >= duration:
		# Mark command as complete
		done = true
		
	# Return ACTIVE status while duration hasn't elapsed
	return Status.ACTIVE
