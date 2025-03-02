extends Node2D

@onready var network_manager: Node = $Network_Manager
@onready var text_edit: TextEdit = $TextEdit
var player_scene = preload("res://scenes/actors/player/player.tscn")
var players = {}

func _ready() -> void:
	print("🚀 Inicializando o jogo...")
	
	#var is_server = true
	#if OS.has_feature("server"):
	if "--server" in OS.get_cmdline_args():
	#if is_server:
		print("🖥️ Rodando como servidor!")
		network_manager.start_server()
	else:
		print("🎮 Rodando como cliente!")
		network_manager.start_client()
	
	#multiplayer.peer_connected.connect(spawn_player)

func spawn_player(id):
	print("📌 Tentando spawnar jogador ID:", id)
	if id in players:
		return
	
	var player = player_scene.instantiate()
	player.id = str(id) #nomeamos o nó com o ID do jogador
	add_child(player)
	player[id] = player
	
	if multiplayer.is_server():
		player.position = Vector2(400, 300) #define a posição inicial para novos jogadores 
