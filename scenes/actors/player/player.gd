extends CharacterBody2D
## Jogador.
##
## O NOME do nó é o id do peer (jogador) que controla este boneco
## (ex.: "1" para o host, "1873264523" para um cliente). Quem define o nome
## é o servidor, em main.gd.
##
## Cada jogador é a "autoridade" do próprio boneco: só ele lê o teclado e
## move o boneco. O MultiplayerSynchronizer (filho deste nó) envia a posição
## e o nome para todo mundo automaticamente.

@export var speed: float = 300.0

## Nome mostrado acima do boneco. Sincronizado pela rede (veja o
## MultiplayerSynchronizer na cena). O "set" atualiza o texto na tela
## sempre que o valor muda, inclusive quando chega pela rede.
@export var player_name: String = "":
	set(valor):
		player_name = valor
		if is_node_ready():
			name_text.text = valor

@onready var name_text: Label = $name_text


func _enter_tree() -> void:
	# Precisa ser no _enter_tree (antes do _ready) para valer também no
	# MultiplayerSynchronizer filho, antes dele começar a sincronizar.
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	if is_multiplayer_authority():
		# Este boneco é MEU: coloco o nome que digitei no menu.
		# O synchronizer envia para os outros.
		player_name = NetworkManager.nome_jogador
		# Destaca o meu boneco para eu saber qual é.
		name_text.modulate = Color(1, 1, 0.4)
	name_text.text = player_name


func _physics_process(_delta: float) -> void:
	# Só quem controla este boneco lê o teclado e move.
	# Nos outros computadores, a posição chega pelo MultiplayerSynchronizer.
	if not is_multiplayer_authority():
		return

	var direcao := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direcao * speed
	move_and_slide()
