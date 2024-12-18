class_name DurativeTraceCommand
extends DurativeAnimationCommand

## Trace player to attack in _duration second
## If successfully approach player, attack and finish command
## Else, attack after _duration second and finish command

var _duration:float
var _target:Character
#positiopns
var _target_position 
var _self_position 
var _distance_x 

func _init(duration:float, target:Character):
	_duration = duration
	_target = target
	
func execute(character:Character) -> Status:
	# Get position
	_target_position = _target.global_position
	_self_position = character.global_position
	_distance_x = _target_position.x - _self_position.x
	# Set timer
	if _timer == null:
		_timer = Timer.new()
		character.add_child(_timer)
		_timer.one_shot = true
		_timer.start(_duration)
		return Status.ACTIVE
	
	if !_timer.is_stopped():
		if _distance_x < -128: # Move left
			character.velocity.x = -character.DEFAULT_MOVE_VELOCITY
			#character.sprite.flip_h = false
			#character.change_facing(Character.Facing.LEFT)
		elif _distance_x > 128: # Move right
			character.velocity.x = character.DEFAULT_MOVE_VELOCITY
			#character.sprite.flip_h = true
			#character.change_facing(Character.Facing.RIGHT)
		elif abs(_distance_x) < 23: # Too close to attack, give up this attack
			return Status.DONE
		else:
			# Adjust direction
			if _distance_x > 0:
				character.sprite.flip_h = true
				character.change_facing(Character.Facing.RIGHT)
			else:
				character.sprite.flip_h = false
				character.change_facing(Character.Facing.LEFT)
			# Stop timer to attack
			character.velocity.x = 0
			_timer.stop()
		return Status.ACTIVE
	else:
		character.cmd_list.push_back(DurativeAttackCommand.new())
		character.cmd_list.push_back(DurativeIdleCommand.new(0.75))
		return Status.DONE
