# Programming Excercise 1: Command Pattern --- from class

## Description

The goals behind this project are 1) to allow for meaningful gameplay gameplay programming inside a Unity project, and 2) 
to provide working experience with the command software design pattern. This project is filled with examples of using Unity 
to construct basic game systems including health, hit/hurt boxes, player movement, non-player character behavior,
parallax scrolling, character movement, a camera that follows the player, animated sprites, boss fights, 
and commands using the Command software design pattern.

## Stage 1: Jump to it
Create a `JumpCommand` class that extends the `Command` class. This command should properly check to see if the `Player` `is_on_floor()` before initiating the jump. You need to provide an appropriate jump velocity that is consistent with the `Player` class so that the `Player` can jump over the obstacle in the level. Additionally, you are required to create a "jump" action in the project's `Input Map` that triggers when the `space`, `up`, or `W` is pressed.  
Note: to make sure the jump sound effects are linked, include `character.command_callback("jump")` when you initiate the jump.  
Note: Look for comments like `#stage1` to see key code areas.  

## Stage 2: A Best Friend  
In this stage, you will create a controller and commands for the follower. 
- A `FollowerController` class that is the brains behind your `Follower`. Through `extend Character`, it contains basic functionality for physics and rendering. It should also have the following functionality:
  - A `_physics_process()` function where the basic logic of the controller is implemented. Be sure to call `super(delta)` to call the movement and rendering code implemented in `character.gd`'s `Character` class.
  - A `_ready()` function where the follower's `movement_speed` and `jump_velocity` are set.
  - When the `Player` is within 5 units of the `Follower`, the follower should initiate a `FollowCommand` (see below) to stay near the `Player`.
  - When the player is higher (i.e., `Player` has a more negative `position.y` than the `Follower`), the `Follower` should use your `JumpCommand` to help reach the player.
- A `FollowCommand` class that enables your `Follower` to be near the player. This class should `extend Command` and include a `leash` member variable representing a maximum distance between the `Follower` and the `Player`. When the two are greater than `leash` units apart, the command should end and `return Status.DONE`.

## Stage 3: Death by a Thousand Cutscenes
This game prototype needs some narrative design. Your task is to create a cutscene just before the boss battle to tell the current story to the player. This cutscene should be between 20 and 30 seconds long and include each of the three characters. 
- Stage the characters in positions in the boss room. It is fine to teleport them to where they need to be.
- The `Player`, `Follower`, and `Boss` should each have `cmd_list` that contains their actions during the cutscene. Please be aware that actions taken by cutscene-controlled characters need to have a duration (most of the `Player`s commands did not have to account for duration). Please consult the classes that `extend DurativeAnimationCommand` to see how to create and use commands with durations.
- Be sure to disable the `Player`'s input before the cutscene starts and enable it before the boss battle. See `bind_player_input_commands()` and `unbind_player_input_commands()` in the `player.gd`.

For examples of how the command lists work, see the paired `BossEncounterTrigger` (in [boss_encounter_trigger.gd](Rut/scripts/boss_encounter_trigger.gd)) and `Boss` classes. The `BossEncounterTrigger` is attached to the `Area2D` trigger named `BossEncounterTrigger` in the `Main` scene. It is responsible for detecting when the `Player` is in the `Boss`s room and configuring the user interface for the boss encounter (e.g., the cutscene followed by the boss battle).

Your work will be assessed on the following criteria:
- The number of unique durative commands across the characters. Less than eight types may result in a point deduction.
- How well synced the three characters' commands are to one another.
- Are the transitions to the cutscene and from the cutscene to the boss battle technically sound.
- **Bonus**: Telling an interesting tale.

To help coordinate these commands, you may wish to use the [cutscene_manager.gd](Rut/scripts/cutscene_manager.gd) as a central control mechanism.

## Stage 4: Boss Mechanics

Make your own boss battle. This is your opportunity to perform self-directed, design-driven gameplay programming. You can implement something as simple as a boss that moves, jumps, and attacks. Or you could make something as elaborate as special moves, life regeneration, damage-absorbing shields made of bone, or a dialogue system to negotiate with the spirit to solve the conflict without violence. Be sure that your boss battle logic uses command lists, is winnable by the player, and follows one of the most essential rules for NPCs: it should always be doing something! Describe your boss battle in a comment near your implementation. This description is for your peer reviewer, so make it clear and communicative.

Good luck!
