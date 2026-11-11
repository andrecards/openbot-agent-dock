# OpenBot Agent Dock para Omarchy

Widget de barra do **Omarchy Shell** que coloca o **Agent Dock do OpenBot** na borda
da tela, sobre as outras janelas, no estilo do dock do macOS — e reaproveita o
próprio dock nativo do app em vez de redesenhar um dock em QML.

O widget mostra o estado do OpenBot na barra, abre um painel de controle e
liga/desliga o modo flutuante do dock.

> **Status:** em desenvolvimento ativo. Nada publicado ainda — repositório privado.

## O que o plugin faz

- **Ícone oficial do OpenBot** na barra, que acompanha o tema: tile branco em
  barra escura (modo preto e modo blur) e tile preto em barra transparente,
  com transição suave.
- **Painel de controle** com: dock acima das outras janelas, abrir o OpenBot e
  reiniciar o app.
- **Comando de terminal** (`openbot-dock-ctl.sh`) com `status`, `open`,
  `dock-on`, `dock-off`, `restart`, `island-off` e `island-on`.
- **IPC do shell** para automações: `omarchy-shell admin.openbot-dock toggle`.

## Como o dock aparece

O OpenBot desenha o Agent Dock em uma janela própria, transparente e sem
moldura. Para ela se comportar como o dock do macOS são necessárias três
peças, e o projeto cuida das três:

| Peça | Onde fica | Papel |
| --- | --- | --- |
| Marcador XWayland | `~/.config/OpenBot/agent-dock-xwayland` | Faz o OpenBot subir em XWayland, condição para a janela do dock ficar acima dos apps. |
| Regra do Hyprland | `hypr/openbot-dock.lua` | Marca as janelas flutuantes do OpenBot com `pin`: dock em todos os workspaces, acima das janelas comuns. `no_shadow` evita a sombra do compositor em volta do painel transparente. |
| Preferência do app | `localStorage` do OpenBot | Escolhe borda direita, auto-hide e faixa fina na borda. |

O auto-hide e a faixa da borda são opções nativas do OpenBot. O plugin liga o
modo flutuante; o comportamento de esconder/mostrar é do próprio app.

Cuidado com regra de janela no Hyprland 0.56: `no_border` **não** é um campo
válido aí (existe só em `workspace_rule`) e faz o compositor recusar a regra
inteira com `unknown field 'no_border'`, deixando também de aplicar o `pin`.

## Requisitos

- **Omarchy** com Omarchy Shell (Quickshell).
- **Hyprland** com configuração em Lua (testado na 0.56).
- **OpenBot** instalado como AppImage em `~/.local/share/AppImages/`.
- `jq`, `bash` e `hyprctl`.

## Instalação

```bash
git clone git@github.com:andrecards/openbot-agent-dock.git
cd openbot-agent-dock
./install.sh
```

O `install.sh` copia o plugin para `~/.config/omarchy/plugins/admin.openbot-dock`,
instala a regra do Hyprland em `~/.config/hypr/openbot-dock.lua`, adiciona o
`require` no `hyprland.lua` (idempotente) e habilita o widget na barra.

Depois, reinicie o shell:

```bash
omarchy restart shell
```

Para remover:

```bash
./install.sh --uninstall
```

## Uso

- **Ponteiro na borda direita:** o dock desliza para fora.
- **Arrastar o dock na vertical:** ajusta a posição (o OpenBot guarda por monitor).
- **Clique no ícone da barra:** painel de controle.
- **Clique do meio no ícone:** reinicia o OpenBot.

### Linha de comando

```bash
~/.config/omarchy/plugins/admin.openbot-dock/openbot-dock-ctl.sh status
~/.config/omarchy/plugins/admin.openbot-dock/openbot-dock-ctl.sh dock-on
~/.config/omarchy/plugins/admin.openbot-dock/openbot-dock-ctl.sh dock-off
~/.config/omarchy/plugins/admin.openbot-dock/openbot-dock-ctl.sh restart
~/.config/omarchy/plugins/admin.openbot-dock/openbot-dock-ctl.sh island-off
~/.config/omarchy/plugins/admin.openbot-dock/openbot-dock-ctl.sh island-on
~/.config/omarchy/plugins/admin.openbot-dock/openbot-dock-ctl.sh theme-system
~/.config/omarchy/plugins/admin.openbot-dock/openbot-dock-ctl.sh theme-default
```

### Tema do dock: Sistema ou Padrão

No painel do widget, a linha **Tema do dock** tem dois botões:

- **Sistema:** o OpenBot (dock e janela principal) usa as cores do tema atual do
  Omarchy. O plugin gera a paleta `~/.config/OpenBot/themes/omarchy.json` a partir
  de `~/.local/state/omarchy/current/theme/colors.toml`, e um gancho em
  `~/.config/omarchy/hooks/theme-set.d/openbot-palette` a regenera a cada troca de
  tema. O OpenBot vigia essa pasta e aplica a paleta **ao vivo, sem reiniciar**.
- **Padrão:** volta ao tema escuro do próprio OpenBot.

Trocar entre Sistema e Padrão reinicia o OpenBot uma vez, porque o app só lê a
escolha de paleta ao iniciar.

### A Dynamic Island do OpenBot

O OpenBot simula o recorte (notch) dos MacBooks: uma janela transparente de
614×380 pontos ancorada **no topo do centro da tela**. No Linux não existe
notch, então ela fica sobre a barra do Omarchy — cobrindo relógio, data e
indicadores — e, por ser transparente, aparece como um retângulo preto com
moldura. O app não tem ajuste de posição: o topo é fixo no código.

Como a barra do Omarchy já mostra o status dos agentes, o plugin trata a ilha
como redundante:

```bash
openbot-dock-ctl.sh island-off   # grava a preferência e reinicia o app
openbot-dock-ctl.sh island-on    # desfaz, volta ao padrão do app
```

O `status` informa em que estado a ilha está (`island=on|off`).

### IPC

```bash
omarchy-shell admin.openbot-dock toggle
omarchy-shell admin.openbot-dock dock
omarchy-shell admin.openbot-dock refresh
```

## Estrutura

```
plugin/                 plugin do Omarchy Shell
  manifest.json         manifesto (schema 1)
  Widget.qml            ícone da barra e painel
  openbot-dock-ctl.sh   status/abrir/ligar/desligar/reiniciar/tema
  openbot-omarchy-palette.py  gera a paleta "Omarchy" do OpenBot
  i18n/                 textos em inglês e português
  icons/                logo do OpenBot (SVG, variantes clara e escura)
hypr/
  openbot-dock.lua      regras de janela (dock e janela principal)
hooks/theme-set.d/
  openbot-palette       gancho do Omarchy: regenera a paleta ao trocar de tema
docs/
  ARQUITETURA.md        decisões técnicas e por quês
install.sh              instalador/desinstalador
```

## Capturas de tela

As imagens entram aqui **depois da avaliação manual**, quando o visual estiver
fechado. Enquanto isso, o repositório fica sem capturas para não fixar um
estado que ainda vai mudar.

## Limitações conhecidas

- A **Dynamic Island** do OpenBot nasce sempre no topo do centro da tela e não
  tem opção de posição no app. Se você quiser usá-la mesmo assim, ela vai
  dividir espaço com a barra do Omarchy; o caminho limpo é mantê-la desligada
  (`island-off`).
- O dock fica ligeiramente acima do centro vertical até ser arrastado: a
  posição é um deslocamento guardado pelo OpenBot por monitor.
- **Cliques na área transparente em volta do dock não chegam aos apps de baixo.**
  A janela do dock é um retângulo fixo (562×512) maior que a parte visível. O
  OpenBot recorta só a forma visível em X11; o Hyprland entrega o ponteiro à
  superfície XWayland inteira, e o XWayland não repassa a forma de entrada a ela.
  Copiar a forma visível para a forma de entrada foi testado e não resolve. Só o
  OpenBot pode corrigir (encolhendo a janela quando o dock está recolhido, como a
  Dynamic Island já faz).
- No OpenBot 0.68.0, o dock pisca em preto enquanto o controle "Tamanho do dock"
  é arrastado ([nightly-labs/openbot#7780](https://github.com/nightly-labs/openbot/issues/7780)).
- Testado apenas em Hyprland com config Lua. Em configs `.conf` antigas a regra
  precisa ser convertida para `windowrulev2`.

## Licença

MIT — veja [LICENSE](LICENSE).
