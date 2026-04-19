extends Node2D

# Simple test main scene to bypass potential Game.gd issues

func _ready() -> void:
	print("Simple main scene loaded successfully!")
	
	# Add player if not already present
	if not has_node("Player"):
		var player_scene = preload("res://scenes/player/Player.tscn")
		var player = player_scene.instantiate()
		player.name = "Player"
		add_child(player)
		player.position = Vector2(400, 300)
	
	# Add simple HUD if not present
	if not has_node("CanvasLayer/HUD"):
		var hud_scene = preload("res://scenes/ui/HUD.tscn")
		var hud = hud_scene.instantiate()
		var canvas_layer = CanvasLayer.new()
		canvas_layer.name = "CanvasLayer"
		add_child(canvas_layer)
		canvas_layer.add_child(hud)
		hud.name = "HUD"
