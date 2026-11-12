# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/)
e versionamento [SemVer](https://semver.org/lang/pt-BR/).

## [Não lançado]

### Problema conhecido: correção pronta no OpenBot
- Cliques perdidos perto do dock (área transparente da janela 562×512): corrigido no código do OpenBot, não no plugin. No branch `fix/xwayland-agent-dock` do clone, a janela do dock fica do tamanho do dock em repouso (6×118 px na faixa da borda) e cresce só enquanto o dock está em uso ou se movendo. Medido no Hyprland 0.56.2 (escala 1,25) com um app Wayland embaixo da área do dock: o app recebeu o ponteiro em 6 de 6 pontos com a correção, contra 2 de 6 no 0.68.0 oficial. Também verificados no build final: chat do dock com teclado real, arrastar o dock e mudar o "Dock size" (a janela fica cheia por 2 s durante mudanças rápidas de tamanho e volta a encaixar). Com isso o Hyprland com patch "clickthrough" e o ajudante `openbot-dock-inputshape.py` foram descartados.
- Ferramenta de teste: o `ydotoold` pode ficar ativo sem mover o cursor (dispositivo virtual travado desde o login); `systemctl --user restart ydotool` resolve. Conferir com `hyprctl cursorpos` antes de medir.

## [1.5.1] - 2026-11-11

### Corrigido
- Paleta "Omarchy" para temas no formato antigo do Omarchy (`color0`..`color15`, `selection_background`, sem `muted`/`selection`): antes o gerador falhava neles; agora os tons neutros que faltam (superfície, borda, texto secundário, moldura) são calculados da mistura do fundo com o texto. Testado nos 26 temas instalados (23 do sistema e 3 do usuário, claros e escuros): todos geram paleta válida.
- `openbot-omarchy-palette.py [colors.toml] [saída.json]` aceita um tema e um destino para testes, sem trocar o tema do sistema.

## [1.5.0] - 2026-11-11

### Adicionado
- Tema do dock: botões **Sistema** e **Padrão** no painel do widget. "Sistema" escolhe a paleta "Omarchy" do OpenBot; "Padrão" volta ao tema escuro do app. Trocar reinicia o OpenBot uma vez (ele só lê a escolha de paleta ao iniciar).
- `plugin/openbot-omarchy-palette.py`: gera `~/.config/OpenBot/themes/omarchy.json` a partir do `colors.toml` do tema atual do Omarchy (12 cores + claro/escuro, gravação atômica). O OpenBot vigia essa pasta e aplica a paleta ao vivo.
- `hooks/theme-set.d/openbot-palette`: gancho do Omarchy que regenera a paleta a cada troca de tema; instalado e removido pelo `install.sh`.
- `openbot-dock-ctl.sh theme-system` / `theme-default`, e `theme=` no `status`.

### Problema conhecido (no OpenBot / XWayland, não no plugin)
- Cliques na área transparente em volta do dock não chegam aos apps de baixo: a janela do dock (562×512) é maior que a parte visível, e o Hyprland entrega o ponteiro à superfície XWayland inteira. Copiar a forma visível do X11 para a forma de entrada foi testado e não resolve, porque o XWayland não repassa a forma de entrada à superfície Wayland.

## [1.4.0] - 2026-11-11

### Corrigido
- Foco pulando para o dock ao passar o mouse: com `input:follow_mouse = 1`, o Hyprland dava o foco à janela do dock a cada hover. A regra `hypr/openbot-dock.lua` agora tem `no_follow_mouse = true` (tira só o foco por hover; `no_focus` foi descartado porque impedia o chat do dock de receber teclado).
- Bots do dock só respondiam no workspace onde a janela principal do OpenBot estava: o Hyprland não renderiza janelas fora da tela, e a janela principal é quem processa as ações do dock. Nova regra com `render_unfocused = true` só para a janela principal.

### Removido
- Flag `--enable-transparent-visuals` do `openbot-dock-ctl.sh`: ela não existe no Chromium 152 do OpenBot e não tinha efeito. A transparência vem da profundidade X11 32, escolhida pelo Chromium quando o Hyprland é dono de `_NET_WM_CM_S0`.

### Problemas conhecidos (no OpenBot, não no plugin)
- **OpenBot 0.68.0, ao mudar o "Tamanho do dock"** (Configurações do OpenBot, controle deslizante): enquanto o controle é arrastado, o dock pisca em preto. O app muda o tamanho real da janela X11 a cada passo, e no XWayland cada tamanho novo começa com um buffer preto até o Chromium pintar. Some assim que o controle é solto; com o tamanho fixo, o dock fica estável. Não há regra do Hyprland que evite isso. Relatado em [nightly-labs/openbot#7780](https://github.com/nightly-labs/openbot/issues/7780).
- **Piscada no uso normal: aparentemente corrigida na 0.68.0.** Com o OpenBot 0.68.0, 340 eventos de arrastar o dock não produziram nenhum quadro preto (amostragem de ~5 capturas/s); na 0.67.1, a primeira rajada já produzia a piscada. A 0.68.0 refez o trecho que aplica a forma do dock (`#applyShape`, com zoom). Use o OpenBot 0.68.0 ou mais novo.
- Piscada preta curta no dock (e, às vezes, um retângulo preto que só some ao trocar de workspace). Em X11, o OpenBot recorta a janela do dock com `setShape` a cada mudança da região de entrada (hover, chat, arrastar); o XWayland do Hyprland não recorta a imagem pela forma, e a área fora do recorte aparece preta até o Chromium repintar. Não há correção possível pelo compositor nem pelo plugin; o dock não existe em Wayland nativo (`aboveAppsWindowKind()` devolve `null`). A correção precisa vir do OpenBot.

## [1.3.0] - 2026-11-11

### Corrigido
- Fundo preto opaco quadrado na dock em repouso: o compositor Hyprland aplicava bordas de 2px, sombras e efeito de blur de vidro sobre a janela transparente flutuante do Electron. A regra em `hypr/openbot-dock.lua` agora zera explicitamente bordas (`border_size = 0`), blur (`no_blur = true`), arredondamento (`rounding = 0`), escurecimento de foco (`no_dim = true`) e animações (`no_anim = true`).
- Prevenção de software rendering no Electron: o script `openbot-dock-ctl.sh` agora limpa preventivamente marcadores de falha de GPU (`gpu-crash.json` e `gpu-start.json`) e passa a flag `--enable-transparent-visuals` ao inicializar via XWayland, garantindo transparência alfa real de 32 bits.

### Adicionado
- Documentação técnica comparativa (`docs/RELATORIO_PROJETOS_OPENBOT_DOCK.md`) e proposta de melhorias avançadas (`docs/PROPOSTA_MELHORIAS_CLAUDE.md`).

## [1.2.0] - 2026-11-11

### Adicionado
- `island-off` e `island-on` no `openbot-dock-ctl.sh`, para ligar e desligar a
  **Dynamic Island** do OpenBot. O `status` agora informa `island=on|off`.

### Corrigido
- Retângulo preto/translúcido vazio, sem conteúdo, aparecendo no topo do centro
  da tela e cobrindo o relógio e a data da barra. Era a janela da **Dynamic
  Island** do OpenBot — 614×380 na escala de 125% do app, ou seja 492×304 na
  tela, ancorada na borda superior. Fora do macOS a ilha não tem o que mostrar,
  mas continua sendo uma janela transparente e ocupa a faixa da barra.
- Regra do Hyprland passou a declarar `no_shadow`: as janelas flutuantes do
  OpenBot são painéis transparentes e não devem receber sombra do compositor.
  O campo `no_border` **não** existe em regra de janela (só em `workspace_rule`)
  e fazia o Hyprland recusar a regra inteira com `unknown field`.

## [1.1.0] - 2026-11-11

### Adicionado
- Ícone oficial do OpenBot na barra, em SVG, com variantes clara e escura.
- Troca automática do ícone conforme o tema da barra (preta, blur e
  transparente), com cross-fade.
- Nota de arquitetura explicando as três peças do dock (marcador XWayland,
  regra do Hyprland e preferência do app).

### Alterado
- Ícone desenhado em QML substituído pelo logo do OpenBot.
- Foco da janela principal passou a usar o dispatcher Lua do Hyprland 0.56.
- "Abrir OpenBot" não encerra mais o app quando só o foco falha.

## [1.0.0] - 2026-11-10

### Adicionado
- Widget de barra com painel de controle do Agent Dock.
- Script `openbot-dock-ctl.sh` com `status`, `open`, `dock-on`, `dock-off` e
  `restart`.
- IPC `admin.openbot-dock` (`toggle`, `dock`, `refresh`).
- Regra do Hyprland que fixa o dock flutuante em todos os workspaces.
- Textos em inglês e português.
