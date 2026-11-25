extends Control
## Menu inicial: o jogador escolhe o nome, o IP e o modo de jogo.
## O menu só guarda as escolhas no NetworkManager e troca para a cena do jogo.
## Quem realmente cria o servidor/cliente é o main.gd, DEPOIS que a cena
## do jogo já está carregada (isso é importante para o MultiplayerSpawner).

const CENA_JOGO := "res://scenes/game/main.tscn"

@onready var campo_nome: LineEdit = %CampoNome
@onready var campo_ip: LineEdit = %CampoIP
@onready var botao_host: Button = %BotaoHost
@onready var botao_cliente: Button = %BotaoCliente
@onready var botao_servidor: Button = %BotaoServidor
@onready var label_erro: Label = %LabelErro


func _ready() -> void:
	# Aberto com --server? Pula o menu e vira servidor dedicado direto.
	if NetworkManager.iniciado_como_servidor_dedicado():
		_iniciar(NetworkManager.Modo.SERVIDOR)
		return

	botao_host.pressed.connect(_iniciar.bind(NetworkManager.Modo.HOST))
	botao_cliente.pressed.connect(_iniciar.bind(NetworkManager.Modo.CLIENTE))
	botao_servidor.pressed.connect(_iniciar.bind(NetworkManager.Modo.SERVIDOR))

	# Preenche os campos com o que foi usado da última vez (se voltou ao menu).
	campo_nome.text = NetworkManager.nome_jogador
	if NetworkManager.endereco != "127.0.0.1":
		campo_ip.text = NetworkManager.endereco

	# Mostra o erro que fez o jogador voltar para o menu (se houver).
	label_erro.text = NetworkManager.ultimo_erro
	NetworkManager.ultimo_erro = ""


func _iniciar(modo: NetworkManager.Modo) -> void:
	var nome := campo_nome.text.strip_edges()
	if nome == "":
		nome = "Jogador %d" % (randi() % 1000)
	var ip := campo_ip.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"

	NetworkManager.modo = modo
	NetworkManager.nome_jogador = nome
	NetworkManager.endereco = ip
	# call_deferred: troca de cena com segurança, fora do processamento do botão.
	get_tree().call_deferred("change_scene_to_file", CENA_JOGO)
