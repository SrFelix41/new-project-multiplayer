extends Node

#var network = NetworkedMultiplayerENet.new()
@export var port: int = 12345
@export var max_player: int = 4
var peer = ENetMultiplayerPeer.new()
var players = {}  # Dicionário para armazenar os jogadores (ID → Node)

func start_server():
	peer.create_server(port, max_player)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	
	print("✅ Servidor iniciado na porta: ", port)
	pass

func start_client(address: String = "127.0.0.1"):
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	print("Conectado ao servidor em ", address)
	pass

func _on_peer_connected(id):
	print("Novo jogador conectado: ", id)
	
	var player_scene = preload("res://scenes/actors/player/player.tscn")
	var player = player_scene.instantiate()
	player.name = str(id)
	add_child(player)
	
	players[id] = player
	
	if multiplayer.is_server():
		print("📢 Enviando nome do jogador para todos os clientes")
		set_player_name.rpc(id, "Jogador " + str(id))

func connect_to_server(ip):
	if multiplayer.multiplayer_peer != null:
		print("⚠️ Cliente já está conectado, ignorando reconexão.")
		return
	
	var erro = peer.create_client(ip, port)
	if erro == OK:
		print("✅ Conectado ao servidor com sucesso!")
		multiplayer.multiplayer_peer = peer
	else:
		print("❌ Erro ao conectar ao servidor!")

@rpc("authority", "reliable")
func set_player_name(id, new_name):
	if id in players:
		players[id].player_name = new_name
		players[id].name_text.text = new_name
	else:
		print("⚠️ Erro: jogador ", id, " não encontrado!")
