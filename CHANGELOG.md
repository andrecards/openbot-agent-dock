# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/)
e versionamento [SemVer](https://semver.org/lang/pt-BR/).

## [Não lançado]

### Em investigação
- Janela secundária transparente do OpenBot (~492×304) pode aparecer como um
  painel vazio com a borda do Hyprland.

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
