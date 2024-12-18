class_name Interface
extends Node2D

# World
@onready var world:World = $".."
#connect player
@onready var punk_player:Player = $"../Punk_Player"
# Start Screen
@onready var start_screen:Control = $Canvas/StartScreen
@onready var start_button:Button = $Canvas/StartScreen/Button
# Health
@onready var health:Control = $Canvas/Health
@onready var health_bar:ProgressBar = $Canvas/Health/ProgressBar
@onready var health_label:Label = $Canvas/Health/Label
# Coins
@onready var coins:Control = $Canvas/Coins
@onready var coins_label:Label = $Canvas/Coins/Label
# Level
@onready var level:Control = $Canvas/Level
@onready var level_label:Label = $Canvas/Level/Label
# Dialogue
@onready var dialogue:Control = $Canvas/Dialogue
@onready var dialogue_title:Label = $Canvas/Dialogue/Title
@onready var dialogue_text:Label = $Canvas/Dialogue/Text
@onready var confirm:Button = $Canvas/Dialogue/Confirm
@onready var cancel:Button = $Canvas/Dialogue/Cancel
# Shop
@onready var shop:Control = $Canvas/Shop
@onready var shop_close:Control = $Canvas/Shop/Close
@onready var shop_container:GridContainer = $Canvas/Shop/ScrollContainer/GridContainer
@onready var upgrade_item:Control = $Canvas/Shop/UpgradeItem
# Blackout 
@onready var blackout:Control = $Canvas/Blackout
@onready var blackout_bg:ColorRect = $Canvas/Blackout/Background
# End Screen
@onready var end_screen:Control = $Canvas/EndScreen
@onready var new_game_button:Button = $Canvas/EndScreen/Button

var current_player:Player
var dialog_state:String

const DIALOG_TEXT = {
	"Shop" = "All I got here are experimental cyberware—stuff the\naverage Joe can't afford.\nThe source? Trust me, you don't wanna know.",
	"Portal" = "Do you want to enter the next level?",
	"DefeatBoss" = "Please defeat boss before entering the next level!"
}

func _ready() -> void:
	# set current player
	current_player = punk_player
	Stats.max_health = 100 + Stats.upgrades["Maximum Health"]*40
	Stats.health = Stats.max_health
	# start screen
	start_screen.visible = true
	start_button.pressed.connect(_on_start_screen)
	# dialogue
	confirm.pressed.connect(_on_confirm_pressed)
	cancel.pressed.connect(_on_cancel_pressed)
	# shop
	shop_close.pressed.connect(_on_shop_close)
	# initiate upgrades in shop
	for item in Stats.upgrades:
		var new_item = upgrade_item.duplicate()
		new_item.name = str(item)
		if (Stats.upgrades[str(item)] >= 10):
			new_item.get_node("Cost").text = "Max"
		else:
			var cost = 2**Stats.upgrades[str(item)] * 100
			new_item.get_node("Cost").text = str(cost)
		new_item.get_node("Label").text = str(item)
		new_item.visible = true
		shop_container.add_child(new_item)
		new_item.get_node("Button").gui_input.connect(Callable(self, "_on_button_gui_input").bind(new_item))
	# end screen
	new_game_button.pressed.connect(_on_new_game)
	
	# test end screen
	#await get_tree().create_timer(5).timeout 
	#Stats.health = 0
		

func _process(_delta: float) -> void:
	# update player status
	Stats.max_health = 100 + Stats.upgrades["Maximum Health"]*40
	health_bar.value = Stats.health
	health_bar.max_value = Stats.max_health
	health_label.text = str(Stats.health) + "/" + str(Stats.max_health)
	coins_label.text = str(Stats.coins)
	level_label.text = "Level: " + str(Stats.level)
	for item in Stats.upgrades:
		var shop_item = shop_container.get_node(str(item))
		if (Stats.upgrades[str(item)] >= 10):
			shop_item.get_node("Cost").text = "Max"
		else:
			var cost = 2**Stats.upgrades[str(item)] * 100
			shop_item.get_node("Cost").text = str(cost)
	if Stats.health <= 0 and end_screen.visible == false:
		end_screen.visible = true
		current_player.unbind_player_input_commands()


func black_out():
	blackout.visible = true
	var tween = get_tree().create_tween()
	tween.tween_property(blackout_bg, "modulate", Color(1,1,1,1), 0.5) 
	await get_tree().create_timer(1).timeout
	tween = get_tree().create_tween()
	tween.tween_property(blackout_bg, "modulate", Color(0,0,0,0), 1) 
	await get_tree().create_timer(1).timeout
	blackout.visible = false


func _on_start_screen():
	start_screen.visible = false
	health.visible = true 
	coins.visible = true
	level.visible = true
	current_player.bind_player_input_commands()
	
	
func _on_new_game():
	
	Stats.reset()
	end_screen.visible = false
	health.visible = false 
	coins.visible = false
	level.visible = false
	black_out()
	await get_tree().create_timer(0.5).timeout
	health.visible = true 
	coins.visible = true
	level.visible = true
	world.new_level()
	current_player.bind_player_input_commands()
	current_player.player_reset()
	
func close_dialog():
	dialogue.visible = false
	

func shop_dialog():
	dialogue.visible = true
	dialog_state = "Shop"
	dialogue_title.text = "Scavenger Trader - Biker"
	dialogue_text.text = DIALOG_TEXT[dialog_state]


func portal_dialog():
	dialogue.visible = true
	if world.boss_dead:
		dialog_state = "Portal"
	else: 
		dialog_state = "DefeatBoss"
	dialogue_title.text = "Portal"
	dialogue_text.text = DIALOG_TEXT[dialog_state]


func _on_confirm_pressed():
	dialogue.visible = false
	if dialog_state == "Shop":
		shop.visible = true
		current_player.unbind_player_input_commands()
	elif dialog_state == "Portal":
		world.new_level()


func _on_cancel_pressed():
	dialogue.visible = false
	
	
func _on_shop_close():
	_play($"Audio/11_Carl-ComeBackAnyTime")
	# Update player status
	punk_player.jump_velocity = punk_player.DEFAULT_JUMP_VELOCITY - Stats.upgrades["Jump Power"]*25
	punk_player.movement_speed = punk_player.DEFAULT_MOVE_VELOCITY + Stats.upgrades["Movement Speed"]*20
	punk_player.attack_cooldown = 0.75 - 0.05 * Stats.upgrades["Attack Speed"]
	# Close UI, return control
	shop.visible = false
	current_player.bind_player_input_commands()
	
	
func _on_button_gui_input(event: InputEvent, item):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_upgrade(item)  # Handle left-click
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_on_refund(item)  # Handle right-click
			

func _on_upgrade(item):
	
	# purchase upgrade
	var cost = 2**Stats.upgrades[item.name] * 100
	if (Stats.upgrades[item.name] >= 10 || cost > Stats.coins):
		_play($"Audio/09_Carl-YouCan'tAffordThat")
		return
	_play($"Audio/07_Carl-BeCarefulWithThat")
	Stats.coins -= cost
	Stats.upgrades[item.name] += 1
	
	# update max health
	if (item.name == "Maximum Health"):
		Stats.health += 40
	
	# cap max upgrade level at 10
	if (Stats.upgrades[item.name] >= 10):
		item.get_node("Cost").text = "Max"
	else:
		item.get_node("Cost").text = str(2**Stats.upgrades[item.name] * 100)
		

func _on_refund(item):
	# refund upgrade
	if Stats.upgrades[item.name] == 0:
		return
	Stats.upgrades[item.name] -= 1
	var cost = 2**Stats.upgrades[item.name] * 100
	Stats.coins += cost
	
	# update max health
	if (item.name == "Maximum Health"):
		Stats.health = max(Stats.health-40, 1)

	item.get_node("Cost").text = str(2**Stats.upgrades[item.name] * 100)
	
func _play(player:AudioStreamPlayer) -> void:
	if !player.playing:
		player.play()
