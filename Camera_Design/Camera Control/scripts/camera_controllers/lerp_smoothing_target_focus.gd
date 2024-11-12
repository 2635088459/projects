# Camera that leads the player's movement and provides focus ahead of motion direction
class_name TargetFocusCamera
extends CameraControllerBase

# Designer-adjustable parameters for camera behavior
@export var lead_speed: float = 18.0  # Higher value for more responsive leading movement
@export var catchup_speed: float = 5.0  # Lower value for smoother return to player
@export var leash_distance: float = 5.0  # Maximum allowed distance between camera and player

func _ready() -> void:
	# Initialize parent camera functionality first
	super()
	# Set initial camera position to match target if it exists
	if target != null:
		position = target.position
	# Enable debug visualization by default
	draw_camera_logic = true

func _process(delta: float) -> void:
	# Skip processing if camera isn't active
	if !current:
		return
	
	# Safety check to prevent errors if target is missing
	if target == null:
		return
	
	# Calculate player's input direction
	# Combines horizontal and vertical input into a normalized 2D vector
	# limit_length(1.0) ensures consistent movement speed in all directions
	var input_dir = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).limit_length(1.0)
	
	# Check if player is providing movement input
	# length_squared() is more efficient than length() for comparison
	var moving = input_dir.length_squared() > 0
	# Start with camera targeting player's position
	var desired_position = target.position
	
	if moving:
		# Calculate how far ahead of the player to position camera
		# Convert 2D input direction to 3D space, maintaining y-level
		var lead_offset = Vector3(input_dir.x, 0, input_dir.y) * leash_distance
		desired_position += lead_offset
		
		# Prevent camera from getting too far from player
		var direction_to_target = desired_position - target.position
		if direction_to_target.length() > leash_distance:
			# Normalize and scale vector to maintain maximum distance
			direction_to_target = direction_to_target.normalized() * leash_distance
			desired_position = target.position + direction_to_target
	
	# Calculate camera movement speed
	# Convert boolean to float (1.0 when moving, 0.0 when stopped)
	var speed_multiplier = float(moving)
	# Blend between lead and catchup speeds based on movement state
	var current_speed = lead_speed * speed_multiplier + catchup_speed * (1.0 - speed_multiplier)
	
	# Smoothly interpolate camera position
	# lerp provides smooth movement, delta makes it frame-rate independent
	position.x = lerp(position.x, desired_position.x, current_speed * delta)
	position.z = lerp(position.z, desired_position.z, current_speed * delta)
	
	# Draw debug visualization if enabled
	if draw_camera_logic:
		draw_logic()
	
	# Process parent camera behavior
	super(delta)

func draw_logic() -> void:
	# Create required 3D objects for visualization
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	# Configure mesh instance for visualization
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Start defining the cross shape
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	
	# Draw horizontal line of the cross
	# Y=1 keeps it slightly above ground for visibility
	immediate_mesh.surface_add_vertex(Vector3(-2.5, 1, 0))
	immediate_mesh.surface_add_vertex(Vector3(2.5, 1, 0))
	
	# Draw vertical line of the cross
	# Uses same Y height as horizontal line
	immediate_mesh.surface_add_vertex(Vector3(0, 1, -2.5))
	immediate_mesh.surface_add_vertex(Vector3(0, 1, 2.5))
	
	immediate_mesh.surface_end()
	
	# Set up material properties for visualization
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	# Add visualization to scene
	add_child(mesh_instance)
	# Reset transform to prevent inheritance issues
	mesh_instance.global_transform = Transform3D.IDENTITY
	# Position cross at camera's XZ but target's Y height
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	# Remove visualization after one frame
	# Prevents memory leaks and visual artifacts
	await get_tree().process_frame
	mesh_instance.queue_free()
