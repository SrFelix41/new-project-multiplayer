# Multiplayer no Godot 4, explicado do zero

[← voltar ao README](../README.md)

Este é um tutorial baseado **neste projeto**. A ideia é você entender cada
peça para conseguir modificar o jogo (ou fazer outro) sozinho.

---

## 1. Os conceitos básicos

### Peer

Cada cópia do jogo conectada na partida é um **peer**. Cada peer tem um
**id** (número inteiro):

- O **servidor sempre tem id `1`**.
- Cada cliente recebe um id aleatório grande (ex.: `1873264523`).

```gdscript
multiplayer.get_unique_id()   # meu id
multiplayer.is_server()       # sou o servidor?
```

### Servidor, cliente e host

- **Servidor:** o "centro" da partida. Todos se conectam nele.
- **Cliente:** conecta no servidor.
- **Host:** um servidor que também joga (tem boneco). No Godot, é só um
  servidor que cria um jogador para o id `1`.
- **Servidor dedicado:** servidor sem boneco, muitas vezes rodando sem janela.

Mesmo no modo host, **os clientes não falam entre si diretamente**. Tudo passa
pelo servidor, que repassa.

### ENet e `MultiplayerPeer`

O Godot usa o **ENet** (sobre UDP) para a conexão. Criar a conexão é sempre:

```gdscript
var peer := ENetMultiplayerPeer.new()
peer.create_server(12345, 4)          # servidor: porta, máx. clientes
# ou
peer.create_client("127.0.0.1", 12345) # cliente: ip, porta
multiplayer.multiplayer_peer = peer    # "liga" a rede na árvore de cenas
```

Isso está em `autoload/network_manager.gd`.

### Sinais de conexão

| Sinal | Quem recebe | Quando |
|---|---|---|
| `multiplayer.peer_connected(id)` | todos | Um peer entrou |
| `multiplayer.peer_disconnected(id)` | todos | Um peer saiu |
| `multiplayer.connected_to_server` | cliente | Conectou com sucesso |
| `multiplayer.connection_failed` | cliente | Não conseguiu conectar |
| `multiplayer.server_disconnected` | cliente | O servidor caiu/fechou |

No projeto, o **servidor** usa `peer_connected` para criar o boneco de quem
entrou (`main.gd → _adicionar_jogador`).

---

## 2. A regra de ouro: o mesmo nó no mesmo caminho

Quando um peer manda algo para um nó (RPC, sincronização), o Godot identifica
o nó pelo **caminho na árvore** (ex.: `/root/Main/Players/1873264523`).

> **O nó precisa existir, com o mesmo caminho, em todos os computadores.**

Se no servidor o jogador está em `/root/Main/Players/123` e no cliente não
existe, ou está em outro lugar, aparecem erros como
`Node not found: ...` e nada funciona. **Esse era o principal problema da
versão antiga do projeto** (veja a seção 7).

É exatamente para resolver isso que existe o **MultiplayerSpawner**.

---

## 3. `MultiplayerSpawner`: criar nós em todos os computadores

O spawner observa um nó (o `spawn_path`, aqui `Players`). Quando o
**servidor** cria um filho ali, o spawner manda os clientes criarem o mesmo.
Quando o servidor remove, os clientes removem. E quem **entra depois** recebe
automaticamente todos os nós que já existiam.

Há dois jeitos de usar:

**a) Lista de cenas** (*Auto Spawn List* no Inspetor): o servidor faz
`add_child(cena.instantiate())` normalmente. O problema é que os clientes
recebem só "crie um player.tscn chamado X", sem dados iniciais como a posição.

**b) `spawn_function` (o que este projeto usa):** você escreve uma função que
cria o nó a partir de um dicionário de dados. O servidor chama
`spawner.spawn(dados)` e **a mesma função roda em todos os computadores, com
os mesmos dados**:

```gdscript
# main.gd
func _ready():
	spawner.spawn_function = _criar_jogador

func _adicionar_jogador(id):   # só no servidor
	spawner.spawn({"id": id, "posicao": Vector2(300, 200)})

func _criar_jogador(dados):    # em TODOS
	var jogador = CENA_JOGADOR.instantiate()
	jogador.name = str(dados["id"])
	jogador.position = dados["posicao"]
	return jogador             # o spawner adiciona em Players sozinho
```

Regras:

- **Só o servidor** chama `spawn()` e remove os nós.
- **Não** chame `add_child` na `spawn_function`. Só retorne o nó.
- Os dados precisam ser tipos simples (números, strings, `Vector2`,
  dicionários/arrays desses).

---

## 4. Autoridade: quem manda em cada nó

Todo nó tem uma **autoridade multiplayer**: o id do peer que "manda" nele. Por
padrão é o servidor (`1`).

Neste projeto, **cada jogador é autoridade do próprio boneco**: ele lê o
teclado, move e informa os outros. Para isso, o nome do nó é o id do dono, e:

```gdscript
# player.gd
func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _physics_process(_delta):
	if not is_multiplayer_authority():
		return   # não é meu: a posição chega pela rede
	# ... ler setas e mover ...
```

Por que `_enter_tree` e não `_ready`? A ordem é `_enter_tree` do pai → filhos
entram → `_ready` dos filhos → `_ready` do pai. Definindo no `_enter_tree` do
Player, a autoridade já vale para o `MultiplayerSynchronizer` filho (o
`set_multiplayer_authority` é recursivo) **antes** de ele começar a funcionar.

> **Autoridade do cliente x do servidor:** deixar o cliente mandar na própria
> posição é simples e responde na hora, mas permite trapaça (um cliente
> modificado pode se teletransportar). Jogos competitivos fazem o cliente
> enviar só os **comandos** (teclas) e o servidor calcular a posição. Para um
> projeto de estudo, a autoridade do cliente é o ponto de partida ideal. Veja
> [PRÓXIMOS PASSOS](PROXIMOS-PASSOS.md).

---

## 5. `MultiplayerSynchronizer`: manter propriedades iguais

O synchronizer pega propriedades do nó e as envia **da autoridade para os
outros**, automaticamente. Você configura no painel **Replicação** (parte de
baixo do editor, com o synchronizer selecionado):

| Propriedade | Spawn | Replicar |
|---|---|---|
| `position` | ✔ | **Sempre** |
| `player_name` | ✔ | **Ao mudar** |

- **Spawn:** envia o valor junto com a criação do nó.
- **Sempre** (*Always*): envia a cada intervalo de sincronização. Bom para
  coisas que mudam o tempo todo.
- **Ao mudar** (*On Change*): só envia quando o valor muda. Bom para nome,
  vida, pontuação.

Como o `player_name` chega pela rede "sozinho", o texto na tela precisa ser
atualizado quando ele muda. Para isso serve o `set` da propriedade:

```gdscript
@export var player_name: String = "":
	set(valor):
		player_name = valor
		if is_node_ready():
			name_text.text = valor
```

> Fluxo da posição de um cliente: cliente (autoridade) → servidor → outros
> clientes. O servidor repassa sozinho (opção `server_relay`, ligada por padrão).

---

## 6. RPC: chamar uma função em outro computador

O projeto atual **não precisa** de RPCs (spawner + synchronizer resolvem
tudo), mas você vai usar para eventos: atirar, conversar, pegar item.

```gdscript
@rpc("any_peer", "call_local", "reliable")
func mandar_mensagem(texto: String):
	print(multiplayer.get_remote_sender_id(), " disse: ", texto)

# chamar em todos:
mandar_mensagem.rpc("oi!")
# chamar só no servidor (id 1):
mandar_mensagem.rpc_id(1, "oi servidor")
```

Opções do `@rpc`:

| Opção | Significado |
|---|---|
| `"authority"` (padrão) | Só a autoridade do nó pode chamar |
| `"any_peer"` | Qualquer peer pode chamar (valide no servidor!) |
| `"call_local"` | Também executa no computador que chamou |
| `"call_remote"` (padrão) | Só executa nos outros |
| `"reliable"` | Garante entrega e ordem (eventos importantes) |
| `"unreliable"` | Pode perder pacotes, mas é mais rápido (posições) |
| `"unreliable_ordered"` | Pode perder, mas nunca chega fora de ordem |

Lembre da regra de ouro: o RPC só funciona se o nó existir **no mesmo
caminho** em quem envia e em quem recebe.

---

## 7. Por que a versão antiga não funcionava

Para aprender com os erros, eis o que acontecia no código anterior (commit
`a892c72`, "Desisto"):

1. **Os jogadores só eram criados no servidor.** O `NetworkManager` criava o
   nó em `_on_peer_connected`, mas esse sinal só estava conectado no servidor.
   Os clientes nunca criavam nenhum boneco, então a tela ficava vazia e todo
   RPC enviado a um jogador dava `Node not found`.
2. **Código duplicado e morto.** O `main.gd` tinha `spawn_player()` e
   `_on_player_connected()`, mas nenhum sinal chamava essas funções. Ficava
   difícil saber qual código realmente rodava.
3. **RPC de nome para um nó que não existia.** O servidor fazia
   `set_player_name.rpc(id, ...)` para todos os clientes, que não tinham aquele
   jogador, e caía no "⚠️ Erro: jogador não encontrado!".
4. **Caminhos diferentes.** Os jogadores eram filhos do `Network_Manager`
   (`/root/Main/Network_Manager/123`). Mesmo se o cliente criasse, teria que
   ser exatamente no mesmo lugar.
5. **O `Label` do nome nunca era encontrado.** O script procurava
   `$player_name`, mas o nó na cena se chamava `name_text`.
6. **Posição por RPC `"any_peer"` sem autoridade definida.** Qualquer peer
   podia mudar a posição de qualquer boneco, e um RPC por frame enviado a
   todos é mais trabalhoso de manter que um synchronizer.
7. **Conexão criada antes da cena.** O cliente trocava de cena e conectava
   quase ao mesmo tempo. Com spawner, isso causaria erro se os dados de rede
   chegassem antes da cena existir.

A nova versão resolve tudo com: **autoload** para guardar as escolhas,
**conectar só depois de carregar a cena**, **MultiplayerSpawner** para criar os
bonecos em todos, **autoridade = id do dono** e **MultiplayerSynchronizer**
para posição e nome.

---

## 8. Como testar e depurar

- Use **Depurar → Personalizar Execução de Instâncias** para abrir 2 ou 3
  janelas (veja [COMO-RODAR](COMO-RODAR.md)).
- No painel **Depurador**, cada instância tem sua aba de erros.
- Na aba **Árvore Remota** (*Remote*) do painel Cena, durante a execução, dá
  para ver os nós de cada instância e conferir se `Players` tem os mesmos
  filhos em todas.
- O **Monitor de Rede** (Depurador → Monitores / Profiler de Rede) mostra
  quantos dados estão sendo enviados.
- Os `print()` do projeto usam emojis (✅ 🔌 👤 👋 ⚠️) para facilitar achar
  os eventos de rede no console.

## Referências oficiais

- [High-level multiplayer (manual do Godot)](https://docs.godotengine.org/en/4.3/tutorials/networking/high_level_multiplayer.html)
- [Multiplayer in Godot 4.0: Scene Replication (blog oficial)](https://godotengine.org/article/multiplayer-in-godot-4-0-scene-replication/)
- [Classe MultiplayerSpawner](https://docs.godotengine.org/en/4.3/classes/class_multiplayerspawner.html)
- [Classe MultiplayerSynchronizer](https://docs.godotengine.org/en/4.3/classes/class_multiplayersynchronizer.html)
