extends GPUParticles3D
@export var enabled : bool:
	set(value):
		enabled = value
		if is_inside_tree():
			emit(global_transform)
		last_emitted = Time.get_ticks_usec()
	get:
		return enabled
var old_transform : Transform3D
var old_transform_time : int
var last_emitted : int

func _process(_delta: float) -> void:
	if not enabled:
		return
	var current_time = Time.get_ticks_usec()
	if not old_transform:
		old_transform = global_transform
		old_transform_time = current_time - 1
	var emit_time = lifetime * 1_000_000 / amount * 1.1
	while last_emitted + emit_time < current_time:
		last_emitted += int(emit_time)
		var w = inverse_lerp(old_transform_time, current_time, last_emitted)
		emit(old_transform.interpolate_with(global_transform, w))
	old_transform = global_transform
	old_transform_time = current_time

func emit(t : Transform3D):
	emit_particle(t, Vector3(), Color(), Color(), EMIT_FLAG_POSITION)
