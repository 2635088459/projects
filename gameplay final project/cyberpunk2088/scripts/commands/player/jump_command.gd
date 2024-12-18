class_name JumpCommand
extends Command

var jump_count:int

func execute(character: Character) -> Status:
	var input = character.jump_velocity 
	character.velocity.y = input
	character.command_callback("jump")
	return Status.DONE
