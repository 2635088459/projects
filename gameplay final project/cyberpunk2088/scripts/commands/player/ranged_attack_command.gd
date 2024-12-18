class_name RangedAttackCommand
extends Command

const bullet_group = preload("res://scenes/attacks/bullet_group.tscn")

func execute(character: Character) -> Status:
	character.ranged_attack()
	return Status.DONE
