class_name DurativeSlashCommand
extends DurativeAnimationCommand

@export var slash_attack = preload("res://scenes/attacks/slash_attack.tscn")
	
func execute(character:Character) -> Status:
	var status:Command.Status = _manage_durative_animation_command(character, "jump")
	if character.slashing:
		return status
	var slash = slash_attack.instantiate()
	character.add_child(slash)
	character.animation_player.play("jump")
	character.command_callback("slash")
	slash.global_position.x = character.global_position.x
	slash.find_child("Sprite2D").flip_h = !character.sprite.flip_h
	slash.find_child("AnimationPlayer").play("slash")
	slash.visible = true
	var direction = (character.player.global_position - character.global_position).normalized()
	var target_position: Vector2 = slash.global_position + direction * 1000
	var tween = character.get_tree().create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(slash, "global_position", target_position, 2)
	tween.tween_callback(slash.queue_free)
	return status
