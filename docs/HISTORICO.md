# Histórico de mudanças

[← voltar ao README](../README.md)

## Reescrita do multiplayer (novembro de 2026)

### Multiplayer consertado

| Antes | Depois |
|---|---|
| `NetworkManager` era um nó dentro da `main.tscn` | Virou **autoload** (`autoload/network_manager.gd`), que sobrevive às trocas de cena |
| Menu instanciava `main.tscn` à mão e conectava ao mesmo tempo | Menu só guarda as escolhas e usa `change_scene_to_file`; a conexão é criada **depois** que a cena carrega |
| Jogadores criados só no servidor, como filhos do `Network_Manager` | `MultiplayerSpawner` com `spawn_function` cria os jogadores em `Players` **em todos os computadores**, com a mesma posição inicial |
| Posição enviada por RPC `any_peer` a cada frame | `MultiplayerSynchronizer` envia `position` e `player_name`; autoridade = id do dono |
| Nome enviado por RPC para nós que não existiam nos clientes | Cada jogador define o próprio nome (digitado no menu) e o synchronizer espalha |
| Script procurava `$player_name`, mas o Label se chamava `name_text` | Corrigido para `$name_text` |
| Sem tratamento de erro de conexão | Volta ao menu com mensagem em caso de falha, queda do servidor ou porta em uso |
| Só "servidor" e "cliente" | Três modos: **Hospedar e Jogar**, **Entrar como Cliente**, **Servidor Dedicado** (também via `--server`) |
| Jogador saía e o boneco ficava | Boneco removido em todos quando o jogador desconecta |
| – | Campo de nome no menu, HUD com status, ESC para sair, nome do próprio boneco em amarelo |

Testado com Godot 4.3 em modo *headless*: servidor dedicado + 2 clientes, e
host + 1 cliente. Nomes, posições iniciais, movimento, entrada tardia e
desconexão foram conferidos em todos os peers.

### Repositório limpo

- Removidos `servidor.exe`, `servidor.console.exe`, `servidor.pck` e dois
  arquivos `servidor.exe~RF*.TMP` (cerca de 250 MB no total) e
  `scenes/actors/player/pla3C15.tmp`.
- `.gitignore` agora ignora `/builds/`, `*.exe`, `*.pck` e temporários.
- O export do Windows passa a gerar `builds/new-project-multiplayer.exe`.

> **Observação:** os executáveis saíram da versão atual, mas continuam no
> **histórico** do Git (commits antigos), então o tamanho do clone não diminui.
> Para apagá-los do histórico seria preciso reescrevê-lo (ex.: `git filter-repo`)
> e forçar o push. Isso não foi feito porque é uma operação destrutiva; faça
> só se o tamanho do repositório incomodar.

### Documentação

- `README.md` reescrito.
- Pasta `docs/` criada com: como rodar, arquitetura, tutorial de multiplayer,
  próximos passos e este histórico.
