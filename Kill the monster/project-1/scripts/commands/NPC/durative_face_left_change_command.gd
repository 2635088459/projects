# durative_face_left_direction_command.gd

extends DurativeAnimationCommand
class_name DurativeFaceLEFTDirectionCommand

# Store the target facing direction
var _direction: Character.Facing

# Initialize command with the specified direction
func _init(direction: Character.Facing):
	# Store the direction for use in execute
	_direction = direction

func execute(character: Character) -> Command.Status:
	# Update character's internal facing state
	character.change_facing(_direction)
	
	# Update sprite flip state based on direction
	# If facing LEFT, flip the sprite horizontally (true)
	# The comparison returns true when facing left, false otherwise
	character.sprite.flip_h = _direction == Character.Facing.LEFT
	
	# Return DONE immediately as this is an instant action
	return Status.DONE
