@tool
class_name TerrainManager
extends MeshInstance3D

@export var noise_seed:int = 1337 :
	set(value):
		noise_seed = value
		_generate_terrain()
		
@export var width:int = 2000 :
	set(value):
		width = value
		_generate_terrain()
		
@export var height:int = 2000 :
	set(value):
		height = value
		_generate_terrain()
		
@export var subdivisions:Vector2i = Vector2i(200, 200) :
	set(value):
		subdivisions = value
		_generate_terrain()
		
@export var amplitude:float = 10.0 :
	set(value):
		amplitude = value
		_generate_terrain()

@export var noise:FastNoiseLite

var _ready_to_generate = false
var _mdt:MeshDataTool = MeshDataTool.new()
var _plane_mesh:PlaneMesh = PlaneMesh.new()

func _ready():
	_ready_to_generate = true
	_generate_terrain()


func _generate_terrain() -> void:
	if !_ready_to_generate:
		return

	_plane_mesh.size = Vector2(width, height)
	_plane_mesh.subdivide_depth = subdivisions.x
	_plane_mesh.subdivide_width = subdivisions.y
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _plane_mesh.get_mesh_arrays())
	_mdt.create_from_surface(array_mesh, 0)
	
	noise.seed = noise_seed
	for index in range(_mdt.get_vertex_count()):
		var v:Vector3 = _mdt.get_vertex(index)
		v.y = noise.get_noise_2d(v.x, v.z) * amplitude
		_mdt.set_vertex(index, v)
	mesh = array_mesh
	mesh.clear_surfaces()
	_mdt.commit_to_surface(array_mesh, 0)
	mesh.clear_surfaces()
	_mdt.commit_to_surface(array_mesh)


func move_vertex_below_position(pos:Vector3, delta:float = 10.0) -> void:
	_mdt = MeshDataTool.new()
	_mdt.create_from_surface(mesh, 0)
	var closest:Vector3 = _mdt.get_vertex(0)
	var closest_index = 0

	#Yes, this is wasteful and doesn't scale well. Luckily, we'll get another crack at it next year.
	for i in range(_mdt.get_vertex_count()):
		var v:Vector3 = _mdt.get_vertex(i)
		if pos.distance_squared_to(v) < pos.distance_squared_to(closest):
			closest = v
			closest_index = i
	
	closest.y += delta
	_mdt.set_vertex(closest_index, closest)
	
	mesh.clear_surfaces() 
	_mdt.commit_to_surface(mesh, 0)
	mesh.clear_surfaces()
	_mdt.commit_to_surface(mesh)
