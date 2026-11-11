# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/)
e versionamento [SemVer](https://semver.org/lang/pt-BR/).

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
