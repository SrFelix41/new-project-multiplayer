# New Project Multiplayer

Projeto de estudo de **multiplayer em Godot 4.3**: vários jogadores se conectam
pela rede, cada um controla seu próprio boneco com as setas do teclado e todos
veem todos se movendo, com os nomes por cima.

![Godot 4.3](https://img.shields.io/badge/Godot-4.3-478cbf) ![Rede: ENet](https://img.shields.io/badge/rede-ENet%20(UDP)-555)

## Início rápido

1. Abra o projeto no **Godot 4.3** (Importar → selecione `project.godot`).
2. Em **Depurar → Personalizar Execução de Instâncias...**, ative
   **Habilitar múltiplas instâncias** e coloque **2** (ou 3).
3. Aperte **F5**. Abrem duas janelas com o menu:
   - Na primeira: digite um nome e clique em **Hospedar e Jogar**.
   - Na segunda: digite outro nome e clique em **Entrar como Cliente**.
4. Mova com as **setas**. O seu boneco tem o nome em amarelo. **ESC** volta ao menu.

Passo a passo completo, inclusive como jogar com outro computador e como rodar
um servidor dedicado: **[docs/COMO-RODAR.md](docs/COMO-RODAR.md)**.

## Modos de jogo

| Botão no menu | O que faz | Tem boneco próprio? |
|---|---|---|
| **Hospedar e Jogar** | Vira servidor **e** jogador ao mesmo tempo | Sim |
| **Entrar como Cliente** | Conecta no IP digitado (vazio = `127.0.0.1`) | Sim |
| **Iniciar Servidor Dedicado** | Só servidor: gerencia a partida, não joga | Não |

Também dá para abrir direto como servidor dedicado pela linha de comando com
`--server` (veja [COMO-RODAR](docs/COMO-RODAR.md#servidor-dedicado)).

## Documentação

| Documento | Para que serve |
|---|---|
| [docs/COMO-RODAR.md](docs/COMO-RODAR.md) | Rodar, testar com várias janelas, jogar em rede, exportar, servidor dedicado, problemas comuns |
| [docs/ARQUITETURA.md](docs/ARQUITETURA.md) | Como o projeto está organizado: cada arquivo, cada cena e o fluxo do jogo |
| [docs/MULTIPLAYER-NO-GODOT.md](docs/MULTIPLAYER-NO-GODOT.md) | **Tutorial**: os conceitos de multiplayer do Godot 4 explicados do zero, e por que a versão antiga não funcionava |
| [docs/PROXIMOS-PASSOS.md](docs/PROXIMOS-PASSOS.md) | Ideias do que estudar/implementar em seguida, com dicas de como fazer |
| [docs/HISTORICO.md](docs/HISTORICO.md) | O que mudou na reescrita e por quê |

## Estrutura

```
project.godot                    configurações (cena inicial, autoload NetworkManager)
autoload/
  network_manager.gd             singleton: guarda escolhas do menu e cria servidor/cliente
scenes/
  menu/menu.tscn + menu.gd       tela inicial (nome, IP, modo)
  game/main.tscn + main.gd       partida: cria/remove jogadores (MultiplayerSpawner)
  actors/player/player.tscn + .gd  jogador: movimento + MultiplayerSynchronizer
export_presets.cfg               preset de exportação para Windows (saída em builds/)
```

## Licença

[MIT](LICENSE).
