# Simple camera that maintains exact position over target
class_name PositionLockCamera
extends CameraControllerBase

func _ready() -> void:
	# Initialize parent class first
	super()
	# Set initial camera position to target position if it exists
	# This prevents camera from starting at origin and jumping to target
	if target != null:
		position = target.position

func _process(delta: float) -> void:
	# Skip processing if this camera isn't currently active
	if !current:
		return
	
	# Safety check to prevent errors if target is missing
	if target == null:
		return
	
	# Directly match target's X and Z position
	# Y position (height) is maintained from CameraControllerBase
	# This creates a perfect overhead follow with no smoothing
	position.x = target.position.x
	position.z = target.position.z
	
	# Draw debug visualization if enabled
	if draw_camera_logic:
		draw_logic()
	
	# Call parent class process (handles common functionality like zoom)
	super(delta)

func draw_logic() -> void:
	# Create objects needed for drawing the cross
	# MeshInstance3D is the visual representation
	var mesh_instance := MeshInstance3D.new()
	# ImmediateMesh allows direct vertex specification
	var immediate_mesh := ImmediateMesh.new()
	# Material defines how the mesh is rendered
	var material := ORMMaterial3D.new()
	
	# Configure the mesh instance
	mesh_instance.mesh = immediate_mesh
	# Disable shadows for debug visualization
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Begin defining the cross shape
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	
	# Draw horizontal line of the cross
	# 5 units wide (-2.5 to +2.5)
	# Y=1 keeps it slightly above the ground
	immediate_mesh.surface_add_vertex(Vector3(-2.5, 1, 0))
	immediate_mesh.surface_add_vertex(Vector3(2.5, 1, 0))
	
	# Draw vertical line of the cross
	# 5 units tall (-2.5 to +2.5)
	# Same Y height as horizontal line
	immediate_mesh.surface_add_vertex(Vector3(0, 1, -2.5))
	immediate_mesh.surface_add_vertex(Vector3(0, 1, 2.5))
	
	# Finish defining the mesh
	immediate_mesh.surface_end()
	
	# Configure material properties
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	# Add mesh to scene and position it
	add_child(mesh_instance)
	# Reset the transform to prevent inheritance
	mesh_instance.global_transform = Transform3D.IDENTITY
	# Position cross at camera's XZ but target's Y
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	# Wait for next frame then remove the mesh
	# This ensures the cross is only shown for one frame
	# and prevents memory leaks from accumulating meshes
	await get_tree().process_frame
	mesh_instance.queue_free()
