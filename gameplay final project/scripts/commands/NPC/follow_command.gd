class_name FollowCommand
extends Command

var leash = 300
var master : Character

func execute(follower: Character) -> Status:
	# Check distance
	if abs(follower.distance_x) > leash:
		follower.idle.execute(follower)
		return Status.DONE
		
	# Move in X direction
	if follower.distance_x > 40:
		follower.right_cmd.execute(follower)
	elif follower.distance_x < -40:
		follower.left_cmd.execute(follower)
	else:
		follower.idle.execute(follower)
	# Move in Y direction
	if (follower.self_position.y - follower.master_position.y) > 16:
		if follower.is_on_floor():
			follower.velocity.y = follower.jump_velocity
	
	return Status.ACTIVE
