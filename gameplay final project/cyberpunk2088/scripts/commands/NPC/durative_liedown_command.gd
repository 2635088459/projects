class_name DurativeLiedownCommand
extends DurativeAnimationCommand

var _duration:float

func _init(duration:float = 1.0):
	_duration = duration
	
func execute(character:Character) -> Command.Status:
	if _timer == null:
		character.rotation_degrees = -80
		_timer = Timer.new()
		character.add_child(_timer)
		_timer.one_shot = true
		_timer.start(_duration)
		return Status.ACTIVE
	
	if !_timer.is_stopped():
		return Status.ACTIVE
	else:
		character.rotation_degrees = 0
		return Status.DONE
