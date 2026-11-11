# Relatório Técnico: Ecossistema OpenBot Dock para Omarchy Shell

> **Data de Elaboração:** 11 de Novembro de 2026  
> **Autor / Tech Lead:** Foguim  
> **Ambiente:** Omarchy OS (Arch Linux, Hyprland 0.56, Quickshell, OpenBot AppImage 0.67.1)

---

## 1. Visão Geral do Projeto

O objetivo do projeto **OpenBot Dock para Omarchy** é integrar nativamente o **Agent Dock** do OpenBot no ambiente desktop Omarchy. A proposta é reproduzir a ergonomia do dock do macOS:
- Permanecer oculto na borda lateral direita da tela;
- Deslizar suavemente para a exibição quando o cursor do mouse se aproxima da borda (*auto-hide*);
- Manter apenas os ícones e assentos dos agentes visíveis de forma flutuante sobre as demais janelas;
- Abrir a interface de conversa completa do agente estritamente sob clique;
- Fornecer um widget dedicado na barra superior do Omarchy para atalho, monitoramento e controle.

Para garantir segurança total no ciclo de desenvolvimento, o trabalho foi dividido em **dois projetos complementares**: a base estável original e a versão experimental refinada.

---

## 2. Projeto 1: `omarchy-openbot-dock` (Base Estável / V1.2.0)

- **Caminho Completo no Disco:**  
  `/home/admin/Projects/ferramentas-sistema/omarchy-openbot-dock/`
- **Repositório Git Oficial:**  
  `https://github.com/andrecards/omarchy-openbot-dock.git`
- **Origem:**  
  Desenvolvido e estruturado inicialmente no ambiente Open Code.

### Arquitetura e Componentes Principais
1. **Widget do Omarchy Shell (`plugin/Widget.qml`):**
   - Integrado ao Quickshell do Omarchy;
   - Ícone oficial do OpenBot em formato vetorial SVG (`icons/openbot-icon-white.svg` e `icons/openbot-icon-black.svg`);
   - Detecção automática de luminosidade do tema da barra com transição suave (*cross-fade*) entre tons claros, escuros e translúcidos;
   - Menu popup com opções de abrir o aplicativo, ligar/desligar o modo flutuante e reiniciar a aplicação.
2. **Script de Controle CLI (`plugin/openbot-dock-ctl.sh`):**
   - Comandos: `status`, `open`, `dock-on`, `dock-off`, `restart`, `island-off`, `island-on`.
3. **Resolução da Dynamic Island (`island-off`):**
   - Correção do retângulo vazio que o OpenBot tentava desenhar no topo da tela (simulação do notch de MacBooks), desligando a ilha para não obstruir os indicadores centrais da barra do Omarchy.
4. **Regra de Janela Básica no Hyprland (`hypr/openbot-dock.lua`):**
   - Fixação em todos os workspaces (`pin = true`) e remoção da sombra do compositor (`no_shadow = true`).

---

## 3. Projeto 2: `omarchy-openbot-dock-exp` (Versão Refinada / Transparência Real)

- **Caminho Completo no Disco:**  
  `/home/admin/Projects/ferramentas-sistema/omarchy-openbot-dock-exp/`
- **Origem:**  
  Criado a partir de fork/cópia segura isolada operada pela equipe Teamwork e Foguim, atendendo à exigência de não quebrar nem adulterar a versão estável em produção.

### O Problema Resolvido: O "Fundo Preto Opaco"
Na versão inicial, ao passar o mouse ou ativar a dock, aparecia um retângulo cinza/preto quadrado opaco cobrindo a área da dock. A investigação forense revelou duas causas simultâneas:
1. **Decorações Globais do Hyprland:** O gerenciador de janelas aplicava bordas de 2px, sombras, cantos arredondados e efeito de blur de vidro sobre a janela transparente do Electron, tornando o fundo opaco.
2. **Fallback de Software Rendering no Electron:** Resíduos de travamentos antigos de aceleração de vídeo criavam o arquivo `gpu-crash.json`, fazendo com que o Electron desativasse a transparência de hardware no XWayland.

### Melhorias Implementadas no `-exp`
1. **Regras Cirúrgicas no Hyprland (`hypr/openbot-dock.lua`):**
   ```lua
   o.window({ class = "^(openbot)$", float = true }, {
     pin = true,
     no_shadow = true,
     border_size = 0,    -- Elimina bordas e contornos
     no_blur = true,       -- Desativa blur na área vazia da janela
     rounding = 0,         -- Remove cantos arredondados fantasmas
     no_dim = true,        -- Impede escurecimento ao perder foco
     no_anim = true,       -- Elimina animações que causavam piscar na transparência
   })
   ```
2. **Saneamento Preventivo de GPU no Script CLI (`openbot-dock-ctl.sh`):**
   - Limpeza automática de marcadores de falha (`gpu-crash.json` e `gpu-start.json`) antes de subir o processo;
   - Passagem explícita da flag `--enable-transparent-visuals` junto com `--ozone-platform=x11`.
3. **Exibição Estritamente Sob Demanda:**
   - Em repouso, apenas os ícones e assentos dos agentes flutuam na tela lateral de forma translúcida;
   - A interface de conversa abre exclusivamente quando o usuário clica em um agente da dock.

---

## 4. Tabela Comparativa Direta

| Característica | `omarchy-openbot-dock` (Original) | `omarchy-openbot-dock-exp` (Refinado) |
| :--- | :--- | :--- |
| **Bordas da Janela** | Borda padrão do Hyprland (2px) | Zerada (`border_size = 0`) |
| **Blur do Compositor** | Ativo (criava efeito fosco opaco) | Desativado (`no_blur = true`) |
| **Cantos Arredondados** | Padrão do tema | Zerado (`rounding = 0`) |
| **Flags de Transparência Electron** | Apenas `--ozone-platform=x11` | Adicionado `--enable-transparent-visuals` |
| **Tratamento de Crash de GPU** | Não limpava `gpu-crash.json` | Limpeza preventiva automática |
| **Visual da Dock em Repouso** | Caixa quadrada opaca visível | Apenas os ícones limpos visíveis |
| **Estado Atual no Desktop** | Preservado no disco como backup | **Ativo e instalado no Omarchy Shell** |

---

## 5. Como Alternar entre as Versões

Ambos os projetos contam com instaladores automatizados e idempotentes:

- **Para manter a versão nova com transparência (Atual):**
  ```bash
  cd /home/admin/Projects/ferramentas-sistema/omarchy-openbot-dock-exp
  ./install.sh
  ```

- **Para reverter à versão estável inicial caso necessário:**
  ```bash
  cd /home/admin/Projects/ferramentas-sistema/omarchy-openbot-dock
  ./install.sh
  ```
