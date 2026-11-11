# Briefing Técnico para o Claude: Oportunidades de Evolução e Melhorias no OpenBot Dock

> **Destinatário:** Claude (Claude Code / Anthropic AI)  
> **Objetivo:** Analisar a arquitetura atual do projeto `omarchy-openbot-dock`, identificar potenciais gargalos e propor refinamentos técnicos e arquiteturais de alto nível.

---

## 1. Contexto do Projeto e Stack Tecnológica

O **OpenBot Dock para Omarchy** é uma solução híbrida que integra o **Agent Dock** do OpenBot (aplicativo desktop para orquestração de agentes de IA desenvolvido em Electron/SolidJS) no ambiente de desktop **Omarchy** (baseado em Arch Linux, compositor Hyprland 0.56 e shell Quickshell/Qt Quick).

### Componentes em Funcionamento Atual:
- **Repositório Base:** `/home/admin/Projects/ferramentas-sistema/omarchy-openbot-dock/`
- **Ambiente Refinado (Ativo):** `/home/admin/Projects/ferramentas-sistema/omarchy-openbot-dock-exp/`
- **Plugin Instalado:** `/home/admin/.config/omarchy/plugins/admin.openbot-dock/`
  - `Widget.qml`: BarWidget em Qt Quick com ícone vetorial SVG adaptável à cor/tema da barra e popup de controle.
  - `openbot-dock-ctl.sh`: Utilitário CLI em Bash para gerenciar ciclo de vida, status, inicialização com flags de GPU e desligamento da Dynamic Island redundante.
  - `i18n/`: Catálogo de internacionalização (EN, PT, PT-BR).
- **Regras do Hyprland:** `/home/admin/.config/hypr/openbot-dock.lua`
  - Regra de janela flutuante com `pin = true`, `border_size = 0`, `no_shadow = true`, `no_blur = true`, `rounding = 0`, `no_dim = true` e `no_anim = true`.

---

## 2. O que já está funcionando perfeitamente
1. A Dock do OpenBot flutua na borda lateral direita sobre todas as janelas do Hyprland.
2. O auto-hide nativo do app recolhe e expande a dock ao toque do mouse.
3. A barra preta opaca quadrada que cobria a janela foi 100% eliminada através do zeramento de bordas/blur no compositor e passagem de `--enable-transparent-visuals`.
4. O widget na barra superior do Omarchy permite alternar a dock, abrir o app e reiniciar o serviço com 1 clique.

---

## 3. Desafios e Áreas onde o Claude Pode Propor Melhorias

Gostaríamos da sua avaliação técnica e sugestões práticas para os seguintes pontos de evolução:

### 🚀 Desafio 1: Eliminar o Polling do Widget QML (Transição para IPC Reativo)
- **Cenário Atual:** O `Widget.qml` utiliza um `Timer` de 5000ms (`interval: 5000`) que executa um subprocesso Bash (`openbot-dock-ctl.sh status`) para checar se o OpenBot está rodando.
- **Pergunta para o Claude:** Como podemos substituir esse polling periódico por um mecanismo de escuta reativa em tempo real mais eficiente no Quickshell (ex: monitorar o PID via procfs, usar DBus, ou ler sockets locais) para reduzir o consumo de CPU a zero em repouso?

### 🚀 Desafio 2: Wayland Puro vs. Dependência do XWayland
- **Cenário Atual:** Para que a janela da dock flutue com click-through e transparência sobre outros aplicativos, o OpenBot atualmente inicializa via XWayland com `--ozone-platform=x11`.
- **Pergunta para o Claude:** Existe viabilidade prática, nas versões modernas do Electron/Chromium com Ozone Wayland (`--ozone-platform=wayland`), de configurar a janela da dock diretamente no protocolo Wayland nativo (usando `wlr-layer-shell` ou regras de subsuperfície do Hyprland), eliminando a dependência do servidor XWayland?

### 🚀 Desafio 3: Status Dinâmico de Agentes em Execução
- **Cenário Atual:** O ícone na barra do Omarchy indica apenas um estado binário: *ligado* (colorido/nítido) ou *desligado* (dimmed/apagado).
- **Pergunta para o Claude:** É viável interceptar ou ler o estado dos agentes locais do OpenBot (ex: inspecionar arquivos temporários, logs ou eventos de IPC do Electron) para exibir um anel pulsante ou badge luminoso na barra quando um agente estiver ativamente gerando código ou executando tarefas?

### 🚀 Desafio 4: Gerenciamento dos "Assentos da Dock" (*Dock Seats*)
- **Cenário Atual:** O usuário precisa abrir a janela completa do OpenBot para definir quais agentes ou modelos de IA aparecem fixados nos assentos da dock lateral.
- **Pergunta para o Claude:** Como estruturar uma integração no popup do `Widget.qml` para ler e gravar diretamente no armazenamento de preferências do app (ou via chamada IPC), permitindo adicionar, remover ou reordenar agentes da dock sem abrir o aplicativo em tela cheia?

### 🚀 Desafio 5: Animações e Micro-interações Visuais no Hyprland
- **Cenário Atual:** Atualmente desativamos as animações da janela da dock com `no_anim = true` para evitar artefatos de renderização e flashes pretos durante a transição de opacidade.
- **Pergunta para o Claude:** Como você configuraria uma curva de animação Bezier customizada no Hyprland que funcione especificamente para o slide lateral da dock flutuante sem reintroduzir flickers ou bordas pretas?

### 🚀 Desafio 6: Preparação para Publicação no Marketplace do Omarchy
- **Cenário Atual:** O repositório está privado e funcionando localmente.
- **Pergunta para o Claude:** Quais melhorias de empacotamento, scripts de teste de CI, documentação em inglês e conformidade com as diretrizes do `plugins.omarchy.org` você recomendaria para tornar este plugin um padrão público oficial para a comunidade?

---

## 4. Instruções para a Resposta do Claude

Ao responder a este documento:
1. Faça uma avaliação crítica priorizando **impacto visual e estabilidade** (evitar complexidade desnecessária).
2. Classifique as propostas em **Ganho Rápido (Quick Wins)** vs. **Evolução Arquitetural de Longo Prazo**.
3. Forneça exemplos de código específicos (snippets QML, regras Lua do Hyprland ou comandos Bash) para as soluções recomendadas.
