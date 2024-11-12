class_name SpeedupPushCamera
extends CameraControllerBase


# push_ratio: When > 1.0, speeds up camera movement in non-edge-touching directions
@export var push_ratio: float = 1.0
# Defines outer box boundaries relative to camera center

@export var pushbox_top_left: Vector2 = Vector2(-8, -6)
@export var pushbox_bottom_right: Vector2 = Vector2(8, 6)
# Defines inner speedup zone boundaries relative to camera center

@export var speedup_zone_top_left: Vector2 = Vector2(-4, -3)
@export var speedup_zone_bottom_right: Vector2 = Vector2(4, 3)

# Small buffer zone to prevent jittering when target is exactly at boundaries
const EDGE_BUFFER: float = 0.1

func _ready() -> void:
	# Initialize parent camera functionality first
	super()
	# Set initial camera position to match target if it exists
	if target != null:
		position = target.position
	# Enable visual debugging by default for development
	draw_camera_logic = true

func _process(delta: float) -> void:
	# Processing is skipped if the camera isn't active or if the target is missing
	if !current or target == null:
		return

	# Draw debug visualization if enabled for development purposes
	if draw_camera_logic:
		draw_logic()

	# Target's world position and camera's world position are cached to minimize property access
	var tpos = target.global_position
	var cpos = global_position

	# Movement vector calculated from user input, ensuring consistent speed across directions
	var movement = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).limit_length(1.0)

	# Camera movement processing is skipped if there's no input
	if movement.length_squared() == 0:
		super(delta)
		return

	# Target's speed is determined by input state, affecting the camera's responsiveness
	var base_speed = target.BASE_SPEED
	if Input.is_action_pressed("ui_accept"):
		base_speed *= target.HYPER_SPEED  # Assuming this is a multiplier

	# The target's position relative to the camera's speedup zones determines the speed and movement logic
	var in_speedup_zone = (
		tpos.x >= cpos.x + speedup_zone_top_left.x and 
		tpos.x <= cpos.x + speedup_zone_bottom_right.x and
		tpos.z >= cpos.z + speedup_zone_top_left.y and 
		tpos.z <= cpos.z + speedup_zone_bottom_right.y
	)

	# Absolute world positions for the outer box boundaries are calculated
	var box_left = cpos.x + pushbox_top_left.x
	var box_right = cpos.x + pushbox_bottom_right.x
	var box_top = cpos.z + pushbox_top_left.y
	var box_bottom = cpos.z + pushbox_bottom_right.y

	# Target's bounding box is adjusted for the buffer zone to smooth edge transitions
	var ball_left = tpos.x - target.WIDTH / 2.0 - EDGE_BUFFER
	var ball_right = tpos.x + target.WIDTH / 2.0 + EDGE_BUFFER
	var ball_top = tpos.z - target.HEIGHT / 2.0 - EDGE_BUFFER
	var ball_bottom = tpos.z + target.HEIGHT / 2.0 + EDGE_BUFFER

	# The target's contact with the boundaries determines how the camera adjusts its position
	var hit_left = ball_left <= box_left
	var hit_right = ball_right >= box_right
	var hit_top = ball_top <= box_top
	var hit_bottom = ball_bottom >= box_bottom

	# New target position is calculated to ensure the target stays within boundaries
	var new_pos = target.position
	if hit_left:
		new_pos.x = box_left + target.WIDTH / 2.0 + EDGE_BUFFER
	if hit_right:
		new_pos.x = box_right - target.WIDTH / 2.0 - EDGE_BUFFER
	if hit_top:
		new_pos.z = box_top + target.HEIGHT / 2.0 + EDGE_BUFFER
	if hit_bottom:
		new_pos.z = box_bottom - target.HEIGHT / 2.0 - EDGE_BUFFER

	# Target is smoothly interpolated to the new position
	target.position = target.position.lerp(new_pos, 0.5)

	# When the target is outside the speedup zone, the camera adjusts its movement strategy
	if !in_speedup_zone:
		var speed_x = base_speed
		var speed_z = base_speed

		if hit_left or hit_right or hit_top or hit_bottom:
			# Different boundary contacts affect the camera's speed in each direction
			if (hit_left and hit_top) or (hit_left and hit_bottom) or (hit_right and hit_top) or (hit_right and hit_bottom):
				speed_x = base_speed
				speed_z = base_speed
			elif hit_left or hit_right:
				speed_x = base_speed
				speed_z = base_speed * push_ratio
			elif hit_top or hit_bottom:
				speed_x = base_speed * push_ratio
				speed_z = base_speed
		else:
			speed_x = base_speed * push_ratio
			speed_z = base_speed * push_ratio

		var target_pos = position
		target_pos.x += movement.x * speed_x * delta
		target_pos.z += movement.y * speed_z * delta
		position = position.lerp(target_pos, 0.3)

	super(delta)  # Process parent camera behavior

# Function to visually debug camera boundaries
func draw_logic() -> void:
	# Instantiating visual elements to render boundary boxes
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)

	# Drawing outer pushbox
	immediate_mesh.surface_add_vertex(Vector3(pushbox_bottom_right.x, 0, pushbox_top_left.y))
	immediate_mesh.surface_add_vertex(Vector3(pushbox_bottom_right.x, 0, pushbox_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(pushbox_bottom_right.x, 0, pushbox_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(pushbox_top_left.x, 0, pushbox_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(pushbox_top_left.x, 0, pushbox_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(pushbox_top_left.x, 0, pushbox_top_left.y))
	immediate_mesh.surface_add_vertex(Vector3(pushbox_top_left.x, 0, pushbox_top_left.y))
	immediate_mesh.surface_add_vertex(Vector3(pushbox_bottom_right.x, 0, pushbox_top_left.y))

	# Drawing inner speedup zone
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_bottom_right.x, 0, speedup_zone_top_left.y))
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_bottom_right.x, 0, speedup_zone_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_bottom_right.x, 0, speedup_zone_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_top_left.x, 0, speedup_zone_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_top_left.x, 0, speedup_zone_bottom_right.y))
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_top_left.x, 0, speedup_zone_top_left.y))
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_top_left.x, 0, speedup_zone_top_left.y))
	immediate_mesh.surface_add_vertex(Vector3(speedup_zone_bottom_right.x, 0, speedup_zone_top_left.y))
	immediate_mesh.surface_end()

	# Setting material properties for visibility
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)

	# Ensuring debug meshes are removed at the end of the frame
	await get_tree().process_frame
	mesh_instance.queue_free()
