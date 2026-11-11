# Arquitetura e decisões

Este documento registra **por que** o plugin é assim. O código é pequeno; o
conhecimento que custou tempo está aqui.

## Princípio: usar o dock do OpenBot, não recriar

O caminho óbvio seria desenhar um dock em QML na barra do Omarchy. Seria um
dock de mentira: sem os agentes reais, sem os resultados de trabalho e sem o
comportamento que o app já implementa.

O OpenBot já desenha um **Agent Dock** nativo em uma janela transparente,
sem moldura, `alwaysOnTop`, com `hasShadow: false` e `skipTaskbar: true`
(`createAgentDockWindow` no bundle principal). O plugin só arruma as condições
para essa janela se comportar como o dock do macOS.

## Peça 1 — XWayland

O próprio OpenBot relança em XWayland quando encontra o marcador:

```
~/.config/OpenBot/agent-dock-xwayland
```

Sem ele, no Wayland puro, a janela do dock não fica sobre os outros apps.
O `openbot-dock-ctl.sh dock-on` cria esse arquivo e reinicia o app com
`--ozone-platform=x11`.

## Peça 2 — Regra do Hyprland

A janela do dock nasce em um workspace e fica atrás das outras. A regra
`hypr/openbot-dock.lua` usa `pin`:

```lua
o.window({ class = "^(openbot)$", float = true }, { pin = true })
```

Detalhe que custou uma investigação: dentro de `match`, o critério de janela
flutuante no Hyprland 0.56 é **`float`**, não `floating`. Com `floating`, a
chave é ignorada em silêncio e a regra passa a valer para todas as janelas do
OpenBot. Foi confirmado com um teste controlado usando `tag` como sonda: em um
workspace com tiling, `float = true` não casou com a janela tiled e
`floating = true` casou.

Consequência prática: só as janelas flutuantes do OpenBot (dock e painéis)
recebem `pin`; a janela principal continua no tiling normal.

## Peça 3 — Preferência do app

O dock guarda a configuração no `localStorage` do Electron, origem
`openbot-app://app`, chave `openbot:agent-dock-preference`:

```json
{
  "shown": true,
  "placement": "screen",
  "display": { "kind": "window" },
  "edge": "right",
  "autoHide": true,
  "edgeStrip": true,
  "results": true,
  "offsets": [{ "displayId": 33, "offset": 0.3613 }]
}
```

`autoHide` faz o dock deslizar para dentro da borda; `edgeStrip` deixa uma
faixa fina visível no lugar onde ele se esconde. Esses dois campos são o
"aparece quando passo o mouse".

Esse valor fica dentro de um LevelDB aberto pelo app. **Não escreva nele por
fora**: o app mantém o banco aberto e sobrescreve o que não conhece. O caminho
suportado é a interface do OpenBot (Configurações → Agent Dock).

`offsets` é o deslocamento vertical por monitor, ajustado arrastando o dock.
Por isso a posição exata é responsabilidade do usuário, não do plugin.

## Ícone da barra

O logo do OpenBot é um tile arredondado com o glifo invertido. Como a barra do
Omarchy muda de cor conforme o modo (preto, blur e transparente), o widget
carrega as duas variantes em SVG e troca por luminância da cor de frente da
barra (`bar.barForeground`), com cross-fade de 180 ms:

- barra escura (preta ou blur) → tile branco
- barra transparente (fundo claro) → tile preto

O SVG é renderizado no tamanho final com `sourceSize` dobrado, então não perde
nitidez em telas HiDPI.

## Renderização do OpenBot

Se as janelas do app ficarem com blocos pretos, ele caiu no renderizador por
software. O marcador `~/.config/OpenBot/gpu-start.json` desliga a GPU; apagar
esse arquivo com o app fechado faz o OpenBot tentar a GPU de novo e, quando dá
certo, ele mesmo remove o marcador.
