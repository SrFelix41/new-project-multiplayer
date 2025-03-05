extends Node2D

@onready var network_manager: Node = $Network_Manager
var player_scene = preload("res://scenes/actors/player/player.tscn")
var players = {}

func _ready():
	if "--server" in OS.get_cmdline_args():
		iniciar_servidor()
	else:
		print("🟡 Rodando como cliente, aguardando conexão do menu...")

func iniciar_servidor():
	print("🖥️ Servidor iniciado.")
	network_manager.start_server()  # Certifique-se de que esta função existe no NetworkManager

func connect_to_server(ip):
	print("🔌 Tentando conectar ao servidor em ", ip)
	network_manager.connect_to_server(ip)  # Função que conecta ao servidor

func _on_player_connected(id):
	print("👤 Novo jogador conectado! ID: ", id)  # Verifica se o jogador está sendo criado
	spawn_player(id)

func spawn_player(id):
	print("📌 Tentando spawnar jogador ID: ", id)
	if id in players:
		return
	
	var player = player_scene.instantiate()
	player.name = str(id) #nomeamos o nó com o ID do jogador
	add_child(player)
	players[id] = player
	
	if multiplayer.is_server():
		player.position = Vector2(400, 300) #define a posição inicial para novos jogadores 

func send_player_name():
	if multiplayer.is_server():
		print("🖥️ Servidor iniciado. Nenhum nome será enviado.") 
		return
	
	var nome = "Jogador " + str(randi() % 1000)
	print("📨 Enviando nome:", nome)
	network_manager.set_player_name.rpc_id(1, multiplayer.get_unique_id(), nome)
