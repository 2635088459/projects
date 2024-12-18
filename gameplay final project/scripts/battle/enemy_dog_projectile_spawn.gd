extends Node2D

var sprite_facing: bool
var a: Node

func _ready() -> void:
	a = get_parent()


func _physics_process(_delta: float) -> void:
	sprite_facing = a.dog_facing()
