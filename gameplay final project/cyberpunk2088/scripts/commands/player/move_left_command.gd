class_name MoveLeftCommand
extends Command


func execute(character: Character) -> Status:
	var input = -1 * character.movement_speed
	character.velocity.x = input
	return Status.DONE
