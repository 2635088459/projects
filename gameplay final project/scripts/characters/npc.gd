class_name Npc
extends CharacterBody2D

@onready var hitbox:Area2D = $Hitbox 
@onready var interface:Interface = get_tree().get_root().get_node("World/Interface")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	hitbox.area_entered.connect(_on_area_entered)
	hitbox.area_exited.connect(_on_area_exited)
	animated_sprite_2d.play("idle") 
	
func _on_area_entered(hurtbox:HurtBox) -> void:
	_play($"01_Carl-Guns,BladesAndAmmunition___")
	if hurtbox.get_owner() is Player: 
		interface.shop_dialog()
		
func _on_area_exited(hurtbox:HurtBox) -> void:
	if hurtbox.get_owner() is Player:
		interface.close_dialog()
		
func _play(player:AudioStreamPlayer) -> void:
	if !player.playing:
		player.play()
