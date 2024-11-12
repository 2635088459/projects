class_name FollowCommand
extends Command

var leash: float = 200.0  # Maximum distance between Follower and Player


	
func execute(character: Character) -> Status:
	if not character is FollowerController:
		return Status.ERROR
	
	var follower := character as FollowerController
	var player := follower.player
	
	if not player:
		#print("FollowCommand: Player not found")
		return Status.ERROR
	
	var distance_to_player = follower.global_position.distance_to(player.global_position)
	#print("FollowCommand: Distance to player: ", distance_to_player)
	
	# If beyond leash distance, end the command
	if distance_to_player > leash:
		#print("FollowCommand: Beyond leash distance, ending command")
		follower.velocity = Vector2.ZERO
		return Status.DONE
	
	# Calculate direction to move
	var direction = player.global_position - follower.global_position
	
	# Update facing direction
	if abs(direction.x) > 4.0:  # Only change facing if there's a significant horizontal difference
		if direction.x > 0:
			character.sprite.flip_h = false
			character.change_facing(Character.Facing.RIGHT)
		else:
			character.sprite.flip_h = true
			character.change_facing(Character.Facing.LEFT)
	
	# Handle horizontal movement --- 5 units 
	if distance_to_player > 40.0:
		#print("FollowCommand: Moving towards player")
		follower.velocity.x = sign(direction.x) * follower.movement_speed
	else:
		#print("FollowCommand: Within 60 units, staying still")
		follower.velocity.x = 0
	
	# Handle jumping separately
	if direction.y < -100 and follower.is_on_floor():
		#print("FollowCommand: Jumping to reach player")
		follower.velocity.y = follower.jump_velocity
	
	return Status.ACTIVE
