# durative_face_right_direction_command.gd
extends DurativeAnimationCommand
class_name DurativeFaceRightDirectionCommand

# Store the facing direction for the character
var _direction: Character.Facing

# Initialize the command with the specified direction
func _init(direction: Character.Facing):
	# Store the direction that will be used in execute
	_direction = direction

func execute(character: Character) -> Command.Status:
	# Update the character's internal facing direction state
	character.change_facing(_direction)
	
	# Update sprite flip state based on direction
	# If facing RIGHT, flip the sprite horizontally (true)
	# Differs from LEFT command as it checks for RIGHT facing
	character.sprite.flip_h = _direction == Character.Facing.RIGHT
	
	# Return DONE immediately since this is an instant action
	# No need for duration or animation timing
	return Status.DONE
