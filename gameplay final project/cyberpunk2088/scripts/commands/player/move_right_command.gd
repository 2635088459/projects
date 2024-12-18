class_name MoveRightCommand
extends Command


func execute(character: Character) -> Status:
	var input = character.movement_speed
	character.velocity.x = input
	return Status.DONE
