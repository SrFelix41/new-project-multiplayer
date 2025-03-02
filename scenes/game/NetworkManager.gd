extends Node

#var network = NetworkedMultiplayerENet.new()
@export var port: int = 12345
@export var max_player: int = 4
var peer = ENetMultiplayerPeer.new()

func start_server():
	peer.create_server(port, max_player)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	
	print("✅ Servidor iniciado na porta", port)
	pass

func start_client(address: String = "127.0.0.1"):
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	print("Conectado ao servidor em ", address)
	pass

func _on_peer_connected(id):
	print("Novo jogador conectado:", id)
	pass
