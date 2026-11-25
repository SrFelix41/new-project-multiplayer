# Como rodar o projeto

[← voltar ao README](../README.md)

## Requisitos

- **Godot 4.3** (versão padrão, não precisa ser a .NET/C#). Baixe em
  <https://godotengine.org/download/archive/4.3-stable/>.
  Versões 4.4+ também devem abrir o projeto (o Godot pode pedir para converter
  arquivos, o que é normal).

## 1. Testar no próprio computador (várias janelas)

O jeito mais fácil de testar multiplayer é abrir várias cópias do jogo no
mesmo PC. O IP `127.0.0.1` (*localhost*) significa "este computador".

1. Abra o projeto no Godot.
2. Menu **Depurar → Personalizar Execução de Instâncias...**
   (*Debug → Customize Run Instances...* em inglês).
3. Marque **Habilitar múltiplas instâncias** e escolha **2** ou **3**.
4. Aperte **F5**.
5. Janela 1 → **Hospedar e Jogar**. Janelas 2 e 3 → **Entrar como Cliente**
   (deixe o IP vazio).

> Dica: as janelas abrem uma em cima da outra. Arraste para o lado para ver
> as duas ao mesmo tempo. A janela que está em foco é a que recebe as setas.

Na parte de cima da tela aparece o status: modo, quantidade de jogadores e
os controles.

### Controles

| Tecla | Ação |
|---|---|
| Setas | Mover o seu boneco (nome em **amarelo**) |
| ESC | Sair da partida e voltar ao menu |

## 2. Jogar com outro computador na mesma rede (Wi-Fi/cabo)

1. No computador que vai hospedar, descubra o IP local:
   - Windows: abra o **Prompt de Comando** e digite `ipconfig`. Procure
     **Endereço IPv4**, algo como `192.168.0.15`.
2. Nesse computador: **Hospedar e Jogar** (ou **Iniciar Servidor Dedicado**).
3. No outro computador: digite esse IP no campo **IP do servidor** e clique em
   **Entrar como Cliente**.

Se não conectar, quase sempre é o **firewall do Windows** bloqueando:

- Na primeira vez que você hospedar, o Windows pergunta se quer permitir o
  acesso à rede. Marque **Redes privadas** e permita.
- Se você clicou em "cancelar" sem querer: Painel de Controle → Firewall do
  Windows → *Permitir um aplicativo* → libere o Godot (ou o seu `.exe`).
- O jogo usa a porta **UDP 12345** (definida em `autoload/network_manager.gd`).

## 3. Jogar pela internet

Pela internet, quem hospeda precisa estar acessível de fora. Opções:

- **Redirecionamento de porta** (*port forwarding*) no roteador: redirecione a
  porta **UDP 12345** para o IP local do computador que hospeda. Os amigos usam
  o seu **IP público** (veja em sites como "qual é meu ip").
  Não funciona em algumas operadoras (CGNAT).
- **VPN de jogos** (Radmin VPN, ZeroTier, Tailscale): todos instalam e entram
  na mesma rede virtual, e você usa o IP que o programa mostra. É o mais fácil e
  não precisa mexer no roteador.
- **Servidor na nuvem** (VPS) rodando o servidor dedicado (veja abaixo).

## Servidor dedicado

Servidor dedicado é uma cópia do jogo que só gerencia a partida, sem boneco e
sem precisar de janela. Três formas de iniciar:

**Pelo menu:** botão **Iniciar Servidor Dedicado**.

**Pelo editor/terminal, sem janela (*headless*):**

```bash
# Windows (no terminal, dentro da pasta do projeto)
Godot_v4.3-stable_win64.exe --headless --path . -- --server

# Linux
./Godot_v4.3-stable_linux.x86_64 --headless --path . -- --server
```

**Pelo jogo exportado:**

```bash
builds\new-project-multiplayer.exe --headless -- --server
```

Tudo depois de `--` é argumento do *jogo* (lido por
`NetworkManager.iniciado_como_servidor_dedicado()`). `--headless` é do Godot e
faz rodar sem janela e sem som. Para parar, use **Ctrl+C** no terminal.

## Exportar (gerar o .exe)

1. **Editor → Gerenciar Modelos de Exportação** → baixe os modelos da 4.3
   (só na primeira vez).
2. **Projeto → Exportar...** → preset **Windows Desktop** → **Exportar Projeto**.
3. O arquivo vai para `builds/new-project-multiplayer.exe` (crie a pasta
   `builds/` se o Godot reclamar).

A pasta `builds/` está no `.gitignore`: executáveis **não** vão para o Git (são
grandes e mudam a cada exportação). Para distribuir, use as *Releases* do
GitHub ou envie o arquivo direto.

> O preset está com `embed_pck=false`, então o export gera **dois arquivos**:
> `new-project-multiplayer.exe` e `new-project-multiplayer.pck`. Os dois
> precisam ficar juntos. Para gerar um arquivo só, marque **Binário → Embutir PCK**
> no preset.

## Problemas comuns

| Sintoma | Causa provável / solução |
|---|---|
| Cliente volta ao menu com "Não foi possível conectar ao servidor." | Servidor não está aberto, IP errado, ou firewall bloqueando. Teste primeiro com `127.0.0.1` no mesmo PC. |
| "Não foi possível abrir o servidor na porta 12345... A porta já está em uso?" | Já existe um servidor aberto (outra janela, ou um servidor dedicado esquecido rodando). Feche-o. |
| "O servidor foi desligado." | Quem hospedava fechou o jogo ou apertou ESC. |
| Setas não movem | Clique na janela para dar foco. Só o boneco com nome **amarelo** é seu. |
| Os bonecos dos outros "teleportam"/tremem | Normal neste projeto de estudo: a posição chega sem interpolação. Veja [PRÓXIMOS PASSOS](PROXIMOS-PASSOS.md#2-movimento-suave-interpolação). |
| Rodei só a cena `main.tscn` (F6) e não apareceu o menu | É esperado: abrir a `main.tscn` direto entra em modo **host** automaticamente. Para escolher o modo, rode o projeto pelo menu (F5). |
