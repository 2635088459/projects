# Camera that automatically scrolls and keeps target within a moving frame
class_name AutoScrollCamera
extends CameraControllerBase

# Export variables for designer tweaking in editor
@export var box_width:float = 16.0  # Width of containment box
@export var box_height:float = 12.0  # Height of containment box
@export var autoscroll_speed: Vector3 = Vector3(5, 0, 0)  # Default scrolls right at 5 units/sec

func _ready() -> void:
	# Initialize parent class
	super()
	# Start camera at target's position
	position = target.position
	# Enable visualization by default
	draw_camera_logic = true

func _process(delta: float) -> void:
	# Skip if camera isn't active
	if !current:
		return
	
	# Draw debug visualization if enabled
	if draw_camera_logic:
		draw_logic()
	
	# Store positions for easier reference and cleaner calculations
	var tpos = target.global_position  # Target's position in world space
	var cpos = global_position        # Camera's position in world space
	
	# Move camera based on auto-scroll speed
	# delta ensures smooth movement regardless of frame rate
	position.x += autoscroll_speed.x * delta
	position.z += autoscroll_speed.z * delta
	
	# BOUNDARY CHECKS
	# For each edge, calculate if target is trying to move outside the frame
	# If so, push them back to the frame boundary
	
	# Left boundary check
	# Calculate difference between target's left edge and frame's left edge
	var diff_between_left_edges = (tpos.x - target.WIDTH / 2.0) - (cpos.x - box_width / 2.0)
	if diff_between_left_edges < 0:
		# If target is beyond left boundary, push it right to the boundary
		target.position.x = cpos.x - box_width / 2.0 + target.WIDTH / 2.0
	
	# Right boundary check
	# Calculate difference between target's right edge and frame's right edge
	var diff_between_right_edges = (tpos.x + target.WIDTH / 2.0) - (cpos.x + box_width / 2.0)
	if diff_between_right_edges > 0:
		# If target is beyond right boundary, push it left to the boundary
		target.position.x = cpos.x + box_width / 2.0 - target.WIDTH / 2.0
	
	# Top boundary check
	# Calculate difference between target's top edge and frame's top edge
	var diff_between_top_edges = (tpos.z - target.HEIGHT / 2.0) - (cpos.z - box_height / 2.0)
	if diff_between_top_edges < 0:
		# If target is beyond top boundary, push it down to the boundary
		target.position.z = cpos.z - box_height / 2.0 + target.HEIGHT / 2.0
	
	# Bottom boundary check
	# Calculate difference between target's bottom edge and frame's bottom edge
	var diff_between_bottom_edges = (tpos.z + target.HEIGHT / 2.0) - (cpos.z + box_height / 2.0)
	if diff_between_bottom_edges > 0:
		# If target is beyond bottom boundary, push it up to the boundary
		target.position.z = cpos.z + box_height / 2.0 - target.HEIGHT / 2.0
	
	# Process parent class behavior (zoom, etc.)
	super(delta)

func draw_logic() -> void:
	# Create objects needed for drawing the frame
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	# Configure mesh instance
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Calculate corners of the frame
	var left:float = -box_width / 2   # Left edge relative to center
	var right:float = box_width / 2   # Right edge relative to center
	var top:float = -box_height / 2   # Top edge relative to center
	var bottom:float = box_height / 2  # Bottom edge relative to center
	
	# Begin drawing the frame box
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	
	# Draw the frame box lines in clockwise order
	# Right vertical line
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	
	# Bottom horizontal line
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	
	# Left vertical line
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	
	# Top horizontal line
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	immediate_mesh.surface_end()
	
	# Configure material properties
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.WHITE
	
	# Add mesh to scene and position it
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	# Clean up mesh after drawing
	await get_tree().process_frame
	mesh_instance.queue_free()
