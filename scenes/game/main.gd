extends Node2D
## Cena principal do jogo.
##
## Responsabilidades:
## 1. Ao abrir, criar o servidor ou o cliente (de acordo com o que foi
##    escolhido no menu e guardado no NetworkManager).
## 2. No SERVIDOR: criar um jogador para cada peer que conecta e remover
##    quando ele sai. O MultiplayerSpawner ("PlayerSpawner") repete a criação
##    e a remoção automaticamente em todos os clientes, inclusive para quem
##    entrar depois (ele recebe todos os jogadores que já estavam lá).
## 3. No CLIENTE: voltar ao menu se a conexão falhar ou o servidor cair.

const CENA_MENU := "res://scenes/menu/menu.tscn"
const CENA_JOGADOR := preload("res://scenes/actors/player/player.tscn")

@onready var players: Node2D = $Players
@onready var spawner: MultiplayerSpawner = $PlayerSpawner
@onready var status: Label = $HUD/Status


func _ready() -> void:
	# A spawn_function é chamada em TODOS os computadores (servidor e clientes)
	# sempre que o servidor chama spawner.spawn(dados). Assim todo mundo cria
	# o jogador com o mesmo nome e a mesma posição inicial.
	spawner.spawn_function = _criar_jogador

	match NetworkManager.modo:
		NetworkManager.Modo.SERVIDOR, NetworkManager.Modo.HOST:
			_iniciar_servidor()
		NetworkManager.Modo.CLIENTE:
			_iniciar_cliente()
		_:
			# Abriu a cena main.tscn direto pelo editor (F6) sem passar pelo menu.
			NetworkManager.modo = NetworkManager.Modo.HOST
			_iniciar_servidor()


func _unhandled_input(event: InputEvent) -> void:
	# ESC: sai da partida e volta para o menu.
	if event.is_action_pressed("ui_cancel"):
		_voltar_ao_menu("")


func _process(_delta: float) -> void:
	_atualizar_status()


# ---------------------------------------------------------------- servidor --

func _iniciar_servidor() -> void:
	if NetworkManager.criar_servidor() != OK:
		_voltar_ao_menu(NetworkManager.ultimo_erro)
		return

	multiplayer.peer_connected.connect(_adicionar_jogador)
	multiplayer.peer_disconnected.connect(_remover_jogador)

	# No modo HOST, o próprio servidor (id 1) também tem um jogador.
	if NetworkManager.modo == NetworkManager.Modo.HOST:
		_adicionar_jogador(1)


## Só roda no servidor. Sorteia a posição inicial e pede ao spawner para
## criar o jogador em todo mundo.
func _adicionar_jogador(id: int) -> void:
	print("👤 Jogador conectou: ", id)
	var posicao := Vector2(randf_range(150, 1000), randf_range(150, 500))
	spawner.spawn({"id": id, "posicao": posicao})


## Roda em TODOS os computadores (é a spawn_function do spawner).
## NÃO chame direto: chame spawner.spawn(dados) no servidor.
## O nó recebe como NOME o id do peer; o player.gd usa esse nome para saber
## quem controla aquele boneco.
func _criar_jogador(dados: Dictionary) -> Node:
	var jogador := CENA_JOGADOR.instantiate()
	jogador.name = str(dados["id"])
	jogador.position = dados["posicao"]
	return jogador  # O spawner adiciona o nó dentro de "Players" sozinho.


## Só roda no servidor. Remover o nó aqui remove em todos os clientes também.
func _remover_jogador(id: int) -> void:
	print("👋 Jogador saiu: ", id)
	var jogador := players.get_node_or_null(str(id))
	if jogador:
		jogador.queue_free()


# ----------------------------------------------------------------- cliente --

func _iniciar_cliente() -> void:
	multiplayer.connected_to_server.connect(func(): print("✅ Conectado! Meu id: ", multiplayer.get_unique_id()))
	multiplayer.connection_failed.connect(_voltar_ao_menu.bind("Não foi possível conectar ao servidor."))
	multiplayer.server_disconnected.connect(_voltar_ao_menu.bind("O servidor foi desligado."))

	if NetworkManager.criar_cliente() != OK:
		_voltar_ao_menu(NetworkManager.ultimo_erro)


# ------------------------------------------------------------------ comum --

func _voltar_ao_menu(mensagem: String) -> void:
	if mensagem != "":
		print("⚠️ ", mensagem)
	NetworkManager.ultimo_erro = mensagem
	NetworkManager.desconectar()
	get_tree().call_deferred("change_scene_to_file", CENA_MENU)


func _atualizar_status() -> void:
	var texto := ""
	match NetworkManager.modo:
		NetworkManager.Modo.SERVIDOR:
			texto = "Servidor dedicado (porta %d)" % NetworkManager.porta
		NetworkManager.Modo.HOST:
			texto = "Hospedando (porta %d)" % NetworkManager.porta
		NetworkManager.Modo.CLIENTE:
			if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				texto = "Conectado em %s" % NetworkManager.endereco
			else:
				texto = "Conectando em %s..." % NetworkManager.endereco
	texto += "  |  Jogadores: %d  |  Setas para mover, ESC para sair" % players.get_child_count()
	status.text = texto
