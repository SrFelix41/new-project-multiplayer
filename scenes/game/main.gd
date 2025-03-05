extends Node2D

@onready var network_manager: Node = $Network_Manager
var player_scene = preload("res://scenes/actors/player/player.tscn")
var players = {}

#@onready var network_manager = $NetworkManager

func _ready():
	if "--server" in OS.get_cmdline_args():
		iniciar_servidor()
	else:
		print("🟡 Rodando como cliente, aguardando conexão do menu...")
	# O cliente será iniciado pelo menu

func iniciar_servidor():
	print("🖥️ Servidor iniciado.")
	network_manager.start_server()  # Certifique-se de que esta função existe no NetworkManager

func connect_to_server(ip):
	print("🔌 Tentando conectar ao servidor em", ip)
	network_manager.connect_to_server(ip)  # Função que conecta ao servidor

func _on_player_connected(id):
	print("👤 Novo jogador conectado! ID:", id)  # Verifica se o jogador está sendo criado

#func _ready() -> void:
	if multiplayer.is_server():
		print("🖥️ Servidor iniciado. Nenhum nome será enviado.") 
		return
	
	var nome = "Jogador" + str(randi() % 1000)  # Nome aleatório para teste
	print("📨 Enviando nome:", nome)
	network_manager.rpc_id(1, "set_player_name", multiplayer.get_unique_id(), nome)

	print("🚀 Inicializando o jogo...")
	
	#var is_server = true
	if OS.has_feature("server"):
	#if "--server" in OS.get_cmdline_args():
	#if is_server:
		print("🖥️ Rodando como servidor!")
		network_manager.start_server()
	else:
		print("🎮 Rodando como cliente!")
		network_manager.start_client()
	
	#multiplayer.peer_connected.connect(spawn_player)
#
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
