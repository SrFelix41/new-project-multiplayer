# Próximos passos

[← voltar ao README](../README.md)

Ideias em ordem de dificuldade, cada uma com uma dica de por onde começar.
Faça uma de cada vez e teste com 2 ou 3 janelas.

## 1. Câmera seguindo o seu boneco (fácil)

Adicione um `Camera2D` como filho do `Player`, com **Enabled** desmarcado. No
`_ready()` do `player.gd`:

```gdscript
if is_multiplayer_authority():
	$Camera2D.enabled = true
```

Cada janela segue só o próprio boneco. Adicione também um cenário (um
`TileMapLayer` ou alguns `Sprite2D`/`StaticBody2D`) na `main.tscn` para
dar a sensação de movimento.

## 2. Movimento suave (interpolação)

Hoje a posição dos outros chega "aos saltos". Em vez de sincronizar
`position` direto, sincronize uma propriedade `posicao_rede` e aproxime aos
poucos nos outros computadores:

```gdscript
@export var posicao_rede := Vector2.ZERO   # no synchronizer, no lugar de position

func _physics_process(delta):
	if is_multiplayer_authority():
		# ... movimento normal ...
		posicao_rede = position
	else:
		position = position.lerp(posicao_rede, 15.0 * delta)
```

Lembre de trocar `.:position` por `.:posicao_rede` na aba **Replicação**, e
de iniciar `posicao_rede = position` no `_ready()`.

## 3. Cor diferente para cada jogador

Gere uma cor a partir do id (`Color.from_hsv(fmod(id * 0.618, 1.0), 0.6, 1.0)`)
e aplique em `$texture.modulate` no `_ready()`. Como todo mundo sabe o id
(é o nome do nó), não precisa nem sincronizar.

## 4. Chat simples (RPC)

1. Adicione um `LineEdit` e um `RichTextLabel` no `HUD` da `main.tscn`.
2. No `main.gd`:

```gdscript
@rpc("any_peer", "call_local", "reliable")
func receber_mensagem(texto: String):
	var autor := players.get_node_or_null(str(multiplayer.get_remote_sender_id()))
	var nome := autor.player_name if autor else "?"
	$HUD/Chat.append_text("[b]%s:[/b] %s\n" % [nome, texto])
```

3. Ao apertar Enter no `LineEdit`: `receber_mensagem.rpc(texto)`.

> Cuidado: com o chat aberto, as setas continuam movendo o boneco. Ignore o
> movimento enquanto o `LineEdit` tiver foco.

## 5. Lista de jogadores / placar

Mostre no HUD os nomes de todos: percorra `players.get_children()` e leia
`player_name`. Para pontuação, adicione `@export var pontos := 0` no player e
coloque no synchronizer como **Ao mudar**.

## 6. Coletáveis (moedas) controlados pelo servidor

Bom exercício de **autoridade do servidor**:

1. Cena `moeda.tscn` (`Area2D`) e outro `MultiplayerSpawner` na `main.tscn`
   apontando para um nó `Moedas`.
2. Só o servidor cria moedas (a cada X segundos, posição aleatória).
3. No `body_entered` da moeda, **só o servidor** decide:
   `if not multiplayer.is_server(): return`. Aí soma ponto no jogador e faz
   `queue_free()` na moeda. O spawner some com ela em todos.

## 7. Lobby antes da partida

Uma tela de espera onde todos aparecem numa lista e o host clica em
"Começar". Dica: mantenha a conexão no `NetworkManager`, guarde os nomes num
dicionário `{id: nome}` sincronizado por RPC, e só então troque para a
`main.tscn` em todos com um RPC `"authority", "call_local", "reliable"`.

## 8. Movimento com autoridade do servidor (avançado)

Para evitar trapaça: o cliente envia só a direção das setas (RPC
`unreliable_ordered` para o servidor ou um segundo synchronizer com
autoridade do cliente), e o servidor move todos os bonecos e sincroniza as
posições (synchronizer com autoridade `1`). Depois, estude
*client-side prediction* para não sentir atraso.

## 9. Servidor dedicado na nuvem

Exporte para **Linux** (preset novo, marque *Dedicated Server* nas opções do
preset), suba num VPS e rode com `--headless -- --server`. Libere a porta UDP
12345 no firewall do provedor.

## Organização de código para quando o projeto crescer

- Separe a configuração de entrada: crie ações próprias em **Projeto →
  Configurações → Mapa de Entrada** (`mover_esquerda` etc.) em vez de usar
  `ui_left`, e assim dá para incluir WASD e controle.
- Uma pasta `assets/` para imagens e sons.
- Mantenha a regra: **só o servidor cria e remove coisas compartilhadas**.
