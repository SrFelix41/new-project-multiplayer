# Arquitetura do projeto

[← voltar ao README](../README.md)

Este documento explica **o que cada arquivo faz** e **o caminho que o jogo
percorre** do menu até os jogadores aparecendo na tela. Para entender os
*conceitos* (peer, autoridade, spawner...), leia
[MULTIPLAYER-NO-GODOT.md](MULTIPLAYER-NO-GODOT.md).

## Visão geral

```
                ┌──────────────────────────────┐
                │ NetworkManager (autoload)    │  vive o jogo todo
                │ modo, endereço, nome, peer   │
                └──────────────▲───────────────┘
                     guarda    │    lê e cria a conexão
            ┌──────────────────┴──────────────────┐
┌───────────┴──────────┐   troca de cena   ┌─────┴──────────────────────────┐
│ Menu (menu.tscn)     │ ────────────────▶ │ Main (main.tscn)               │
│ nome, IP, 3 botões   │ ◀──────────────── │  ├─ Players       (Node2D)     │
└──────────────────────┘  erro / ESC       │  ├─ PlayerSpawner (Spawner)    │
                                           │  └─ HUD/Status    (Label)      │
                                           └─────┬──────────────────────────┘
                                                 │ spawner.spawn() cria
                                           ┌─────▼──────────────────────────┐
                                           │ Player (player.tscn) × N       │
                                           │  ├─ texture, collision         │
                                           │  ├─ name_text (Label)          │
                                           │  └─ MultiplayerSynchronizer    │
                                           └────────────────────────────────┘
```

## Arquivos

### `project.godot`

- **Cena inicial:** `res://scenes/menu/menu.tscn`.
- **Autoload:** `NetworkManager="*res://autoload/network_manager.gd"`.
  O `*` faz o Godot criar o nó automaticamente ao iniciar o jogo, em
  `/root/NetworkManager`. Qualquer script pode acessá-lo só escrevendo
  `NetworkManager`.
- **Janela:** 1152×648.

### `autoload/network_manager.gd`, o "gerente de rede"

Um *singleton* (existe um só, o jogo todo). Ele **sobrevive às trocas de cena**,
por isso é onde ficam as informações que o menu passa para o jogo.

| Membro | Tipo | Descrição |
|---|---|---|
| `Modo` | enum | `NENHUM`, `SERVIDOR`, `HOST`, `CLIENTE` |
| `PORTA_PADRAO` | const | `12345` |
| `MAX_JOGADORES` | const | `4` (máximo de clientes conectados ao mesmo tempo) |
| `modo` | `Modo` | Escolhido no menu |
| `endereco` | `String` | IP do servidor (para cliente) |
| `porta` | `int` | Porta usada |
| `nome_jogador` | `String` | Nome digitado no menu |
| `ultimo_erro` | `String` | Mensagem mostrada no menu ao voltar por erro |
| `iniciado_como_servidor_dedicado()` | `bool` | `true` se o jogo foi aberto com `--server` |
| `criar_servidor()` | `Error` | Cria um `ENetMultiplayerPeer` servidor e coloca em `multiplayer.multiplayer_peer` |
| `criar_cliente()` | `Error` | Igual, mas como cliente. **Assíncrono:** retorna `OK` quando a *tentativa* começou; o resultado chega pelos sinais `connected_to_server` / `connection_failed` |
| `desconectar()` | `void` | Fecha a conexão, troca por `OfflineMultiplayerPeer` e volta o modo para `NENHUM` |

Ele **não cria jogadores**. Isso é trabalho da cena `main`.

### `scenes/menu/menu.tscn` + `menu.gd`

Tela inicial. Nós com `%` (nome único) para o script achar fácil:
`%CampoNome`, `%CampoIP`, `%BotaoHost`, `%BotaoCliente`, `%BotaoServidor`,
`%LabelErro`.

Fluxo do `menu.gd`:

1. `_ready()`: se o jogo foi aberto com `--server`, já chama
   `_iniciar(SERVIDOR)` e pula o menu.
2. Senão, conecta os botões, preenche os campos com o que foi usado antes e
   mostra `NetworkManager.ultimo_erro` (se voltou ao menu por erro).
3. `_iniciar(modo)`: guarda modo, nome (ou "Jogador N" se vazio) e IP (ou
   `127.0.0.1`) no `NetworkManager` e **troca para `main.tscn`**.

> **Por que o menu não cria a conexão?** Porque o `MultiplayerSpawner` da cena
> do jogo precisa **já existir** quando os dados de rede chegam. Se o cliente
> conectasse ainda no menu, o servidor mandaria "crie o jogador X" para um
> spawner que ainda não foi carregado, e daria erro. Então: primeiro troca de
> cena, depois conecta.

### `scenes/game/main.tscn` + `main.gd`, a partida

Nós da cena:

| Nó | Tipo | Para que serve |
|---|---|---|
| `Main` | `Node2D` | Raiz, com o script `main.gd` |
| `Players` | `Node2D` | Onde ficam os jogadores. Os nomes dos filhos são os ids dos peers |
| `PlayerSpawner` | `MultiplayerSpawner` | `spawn_path = ../Players`. Replica criação/remoção de jogadores para os clientes |
| `HUD/Status` | `Label` num `CanvasLayer` | Texto de status no topo |

Funções do `main.gd`:

| Função | Roda em | O que faz |
|---|---|---|
| `_ready()` | todos | Define `spawner.spawn_function = _criar_jogador` e inicia servidor ou cliente conforme `NetworkManager.modo`. Se a cena foi aberta direto (F6), assume HOST |
| `_iniciar_servidor()` | servidor | Cria o servidor; conecta `peer_connected` → `_adicionar_jogador` e `peer_disconnected` → `_remover_jogador`. No modo HOST, adiciona o jogador id `1` (o próprio host) |
| `_adicionar_jogador(id)` | servidor | Sorteia uma posição e chama `spawner.spawn({"id": id, "posicao": pos})` |
| `_criar_jogador(dados)` | **todos** | É a `spawn_function`: instancia `player.tscn`, nomeia com o id e aplica a posição. O spawner chama isso no servidor e em cada cliente com os **mesmos dados** |
| `_remover_jogador(id)` | servidor | `queue_free()` no jogador; o spawner remove nos clientes |
| `_iniciar_cliente()` | cliente | Conecta sinais de sucesso/falha/queda e chama `criar_cliente()` |
| `_voltar_ao_menu(msg)` | todos | Guarda a mensagem, desconecta e volta para o menu |
| `_unhandled_input()` | todos | ESC → `_voltar_ao_menu("")` |
| `_atualizar_status()` | todos | Atualiza o texto do HUD a cada frame |

### `scenes/actors/player/player.tscn` + `player.gd`, o jogador

Nós da cena:

| Nó | Tipo | Para que serve |
|---|---|---|
| `Player` | `CharacterBody2D` | Raiz, com `player.gd` |
| `texture` | `Sprite2D` | Ícone do Godot como "boneco" |
| `collision` | `CollisionShape2D` | Retângulo 128×128 |
| `name_text` | `Label` | Nome acima do boneco |
| `MultiplayerSynchronizer` | `MultiplayerSynchronizer` | Envia `position` (sempre) e `player_name` (quando muda) da autoridade para todos |

Configuração de replicação do synchronizer:

| Propriedade | Spawn | Modo | Por quê |
|---|---|---|---|
| `.:position` | sim | **Sempre** (`replication_mode = 1`) | Muda o tempo todo |
| `.:player_name` | sim | **Ao mudar** (`replication_mode = 2`) | Muda uma vez só; economiza rede |

O `player.gd`:

- `_enter_tree()`: `set_multiplayer_authority(name.to_int())`. O nome do nó é
  o id do peer, então **cada jogador é autoridade do próprio boneco**.
  Precisa ser no `_enter_tree` para valer antes do synchronizer começar.
- `_ready()`: se sou a autoridade, uso `NetworkManager.nome_jogador` como nome
  (o synchronizer espalha) e pinto o nome de amarelo.
- `_physics_process()`: se **não** sou a autoridade, não faço nada (a posição
  chega pela rede). Se sou, leio as setas com `Input.get_vector` e chamo
  `move_and_slide()`.
- `player_name` tem um `set` que atualiza o `Label` sempre que o valor muda,
  inclusive quando o valor chega pela rede.

## Fluxo completo (exemplo: host + 1 cliente)

```
HOST (id 1)                                   CLIENTE (id 8273...)
───────────                                   ────────────────────
Menu → "Hospedar e Jogar"
NetworkManager.modo = HOST
troca para main.tscn
main._ready → criar_servidor() (porta 12345)
_adicionar_jogador(1)
  spawner.spawn({id:1, pos})
  └ _criar_jogador → nó "1" em Players
     player._enter_tree → autoridade = 1
     player._ready → é meu: nome = "Ana"
                                              Menu → "Entrar como Cliente"
                                              troca para main.tscn
                                              main._ready → criar_cliente()
            ◀──────────── conexão ENet ─────────────▶
peer_connected(8273...)                       connected_to_server
_adicionar_jogador(8273...)
  spawner.spawn({id:8273..., pos})
  └ cria nó "8273..."  ──── spawner replica ───▶ spawner recebe:
                           os nós "1" e "8273..."  _criar_jogador({id:1,...})
                                                   _criar_jogador({id:8273,...})
                                                   nó "8273..." → autoridade = eu
                                                   _ready → é meu: nome = "Bia"

loop: lê setas, move "1" ──── synchronizer ────▶ atualiza posição de "1"
atualiza posição de "8273..." ◀── synchronizer ── loop: lê setas, move "8273..."
```

Quando o cliente fecha: o host recebe `peer_disconnected` → `_remover_jogador`
→ `queue_free()` → o spawner remove o nó em todos os outros clientes.

Quando o host fecha: o cliente recebe `server_disconnected` → volta ao menu
com "O servidor foi desligado."

## Convenções

- Código, comentários e nomes de nós em **português**; nomes herdados
  (`player_name`, `name_text`, `speed`, `Players`) mantidos para não quebrar
  as cenas.
- Nome do nó do jogador **sempre** = id do peer (`str(id)`). Várias partes
  dependem disso (autoridade, remoção).
- Só o **servidor** cria ou remove jogadores. Clientes nunca chamam
  `spawner.spawn()` nem `queue_free()` em jogadores.
