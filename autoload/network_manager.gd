extends Node
## NetworkManager (autoload / singleton)
##
## Fica carregado durante o jogo inteiro (veja Projeto > Configurações do
## Projeto > Autoload). Guarda as escolhas feitas no menu (modo, IP, nome)
## e cria a conexão de rede (o "peer").
##
## Ele NÃO cria jogadores: quem faz isso é a cena principal (main.gd),
## junto com o MultiplayerSpawner.

## Modos possíveis de iniciar o jogo.
enum Modo {
	NENHUM,    ## Ainda não escolheu (está no menu).
	SERVIDOR,  ## Servidor dedicado: só gerencia, não tem jogador próprio.
	HOST,      ## Servidor + jogador ao mesmo tempo (quem hospeda também joga).
	CLIENTE,   ## Conecta em um servidor existente.
}

const PORTA_PADRAO := 12345
const MAX_JOGADORES := 4

var modo: Modo = Modo.NENHUM
var endereco: String = "127.0.0.1"
var porta: int = PORTA_PADRAO
var nome_jogador: String = ""

## Mensagem mostrada no menu quando algo dá errado (ex.: conexão caiu).
var ultimo_erro: String = ""


## Retorna true se o jogo foi aberto com o argumento --server
## (ex.: `godot --headless -- --server` ou `jogo.exe --server`).
func iniciado_como_servidor_dedicado() -> bool:
	return "--server" in OS.get_cmdline_args() or "--server" in OS.get_cmdline_user_args()


## Cria o servidor. Retorna OK ou um código de erro do Godot.
func criar_servidor() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var erro := peer.create_server(porta, MAX_JOGADORES)
	if erro != OK:
		ultimo_erro = "Não foi possível abrir o servidor na porta %d (erro %d). A porta já está em uso?" % [porta, erro]
		return erro
	multiplayer.multiplayer_peer = peer
	print("✅ Servidor ouvindo na porta ", porta)
	return OK


## Começa a conectar em um servidor. Retorna OK se a tentativa começou;
## o resultado real chega depois pelos sinais `multiplayer.connected_to_server`
## ou `multiplayer.connection_failed`.
func criar_cliente() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var erro := peer.create_client(endereco, porta)
	if erro != OK:
		ultimo_erro = "Não foi possível iniciar a conexão com %s:%d (erro %d)." % [endereco, porta, erro]
		return erro
	multiplayer.multiplayer_peer = peer
	print("🔌 Conectando a ", endereco, ":", porta, "...")
	return OK


## Fecha a conexão atual (se houver) e volta ao estado inicial.
func desconectar() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	# OfflineMultiplayerPeer = "sem rede". Evita erros de RPC depois de desconectar.
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	modo = Modo.NENHUM
