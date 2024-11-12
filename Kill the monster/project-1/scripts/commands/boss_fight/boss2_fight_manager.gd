# boss2_fight_manager.gd
class_name Boss2FightManager
extends Node

"""
Boss Fight Design: "The Child-Stealing Demon"

This boss fight features a demon that has captured a child and taunts the player about it.
The fight consists of a repeating pattern that demonstrates the demon's aggressive and
sadistic nature:

Pattern Breakdown:
1. Opening Sequence:
   - Moves left while facing right, showing agile movement
   - Attacks the player
   - Changes direction and moves right while facing left
   - Taunts the player about eating the child
   - Performs a jump attack combination

2. Mid-Fight Combination:
   - Executes a right-side assault with jumping attacks
   - Quickly changes direction for a left-side attack sequence
   - Maintains pressure through constant movement and attacks

3. Final Sequence:
   - Threatens to destroy the town
   - Performs a final attack combination with jumping
   - Takes a brief pause before repeating the pattern

The boss uses directional changes and face commands to create fluid, natural-looking
movement while attacking. The dialogue integrates with the fight to tell the story
of the demon's malevolent intentions toward both the child and the town. The pattern
repeats until the boss is defeated, with each cycle maintaining consistent pressure
on the player through a mix of movement, jumps, and attacks.

Combat Elements:
- Alternates between left and right movements to cover the arena
- Uses face direction changes to maintain proper visual orientation
- Combines jumps with attacks for varied assault patterns
- Intersperses threatening dialogue to maintain narrative tension

The fight ends when the boss's health reaches zero, at which point all commands
are cleared and the fight sequence terminates.
"""

# References to key characters
var boss: Boss             # The boss being managed
var player: Player        # The player reference for targeting
var is_fight_active: bool = false  # Track if fight is ongoing

# Initialize the manager with necessary references
func _init(boss_node: Boss, player_node: Player):
	boss = boss_node
	player = player_node

# Start the boss fight sequence
func start_fight() -> void:
	is_fight_active = true
	_create_boss_pattern()

# Create and manage boss's attack pattern
func _create_boss_pattern() -> void:
	# Stop pattern creation if boss is dead
	if boss._death:
		is_fight_active = false
		return
		
	# Define boss's command sequence
	var commands: Array[Command] = [
		# First attack sequence
		# Turn right and move left
		DurativeChangeFaceCommand.new(Character.Facing.RIGHT, 0.1),
		DurativeMoveRightCommand.new(1.5),
		DurativeAttackCommand.new(),
		# Turn left and move right
		DurativeChangeFaceCommand.new(Character.Facing.LEFT, 0.1),
		DurativeMoveLeftCommand.new(2.0),
		DurativeJumpCommand.new(0),
		DurativeAttackCommand.new(),
		
		# Second attack combination
		# Right side attack sequence
		DurativeChangeFaceCommand.new(Character.Facing.RIGHT, 0.1),
		DurativeMoveRightCommand.new(1.5),
		DurativeJumpCommand.new(0),
		DurativeAttackCommand.new(),
		# Left side attack sequence
		DurativeChangeFaceCommand.new(Character.Facing.LEFT, 0.1),
		DurativeMoveLeftCommand.new(1.5),
		DurativeAttackCommand.new(),
		
		# Final attack sequence with threat
		DurativeDialogueCommand.new("Demo: I ate that kid! You are the next", 2.0),
		DurativeChangeFaceCommand.new(Character.Facing.RIGHT, 0.1),
		DurativeMoveRightCommand.new(1.0),
		DurativeAttackCommand.new(),
		DurativeJumpCommand.new(0),
		
		# Pause before next pattern
		DurativeIdleCommand.new(1.0)
	]
	
	# Only append commands if boss is still alive
	if not boss._death:
		boss.cmd_list.append_array(commands)
		
		# Set up next pattern after a short delay
		await get_tree().create_timer(0.1).timeout
		# Continue pattern if boss is still alive and fight is active
		if is_fight_active and not boss._death:
			_create_boss_pattern()

# Stop the fight and clear remaining commands
func stop_fight() -> void:
	is_fight_active = false
	if boss and not boss.cmd_list.is_empty():
		boss.cmd_list.clear()

# Monitor boss state and stop fight if needed
func _process(_delta: float) -> void:
	if is_fight_active and boss._death:
		stop_fight()
		
