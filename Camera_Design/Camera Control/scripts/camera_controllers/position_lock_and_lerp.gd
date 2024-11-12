class_name SmoothLockCamera
extends CameraControllerBase

# Export variables allow designers to tune camera behavior in the editor
@export var follow_speed: float = 5.0  # Lower speed for smoother following during movement
@export var catchup_speed: float = 10.0  # Higher speed for quick catch-up when target stops
@export var leash_distance: float = 5.0  # Maximum allowed distance before forced catch-up

func _ready() -> void:
	# Initialize camera using parent class initialization
	super()
	# Set initial position to target's position if target exists
	if target != null:
		position = target.position
	# Enable debug visualization by default
	draw_camera_logic = true

func _process(delta: float) -> void:
	# Skip processing if camera is not active
	if !current:
		return
	
	# Safety check to prevent null reference errors
	if target == null:
		return
	
	# Create target position at same height as camera but X/Z of target
	# This maintains camera height while following target
	var target_pos = Vector3(target.position.x, position.y, target.position.z)
	# Calculate straight-line distance to target for leash checking
	var distance_to_target = position.distance_to(target_pos)
	
	# Get input vector and convert to magnitude (0 to 1)
	# This determines if target is moving and how fast
	var target_velocity = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).length()
	
	# Calculate current speed using boolean to float conversion
	# When target_velocity > 0: follow_speed * 1 + catchup_speed * 0 = follow_speed
	# When target_velocity = 0: follow_speed * 0 + catchup_speed * 1 = catchup_speed
	var current_speed = follow_speed * float(target_velocity > 0) + catchup_speed * float(target_velocity <= 0)
	
	# Override speed if target is too far away
	# This prevents target from getting too far from camera
	if distance_to_target > leash_distance:
		current_speed = catchup_speed  
	
	# Use lerp for smooth interpolation between current and target position
	# delta ensures movement is framerate independent
	# current_speed controls how quickly we move toward target
	position.x = lerp(position.x, target_pos.x, current_speed * delta)
	position.z = lerp(position.z, target_pos.z, current_speed * delta)
	
	# Draw debug visualization if enabled
	if draw_camera_logic:
		draw_logic()
	
	# Call parent class process
	super(delta)

func draw_logic() -> void:
	# Create necessary objects for drawing
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	# Set up mesh instance
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Begin drawing lines for the cross
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	
	# Draw horizontal line of cross (5 units wide)
	immediate_mesh.surface_add_vertex(Vector3(-2.5, 1, 0))
	immediate_mesh.surface_add_vertex(Vector3(2.5, 1, 0))
	
	# Draw vertical line of cross (5 units tall)
	immediate_mesh.surface_add_vertex(Vector3(0, 1, -2.5))
	immediate_mesh.surface_add_vertex(Vector3(0, 1, 2.5))
	
	immediate_mesh.surface_end()
	
	# Configure material properties
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	# Add mesh to scene and position it
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	# Clean up mesh after one frame to prevent memory leaks
	await get_tree().process_frame
	mesh_instance.queue_free()
