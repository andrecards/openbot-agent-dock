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

## O retângulo preto no topo: Dynamic Island

Antes de qualquer suspeita sobre o plugin, o sintoma: um retângulo preto,
translúcido, sem conteúdo, no **topo do centro da tela**, cobrindo relógio e
data da barra, às vezes com uma borda quadrada aparecendo na lateral.

Não era o dock. Era a **Dynamic Island** do OpenBot — o app simula o recorte dos
MacBooks e, para isso, cria uma janela transparente ancorada na borda superior:

```js
var DYNAMIC_ISLAND_WINDOW_SIZE = { width: 614, height: 380 };
```

Com a escala de 125% do monitor, isso vira 492×304 na tela. A geometria vem de
`MACBOOK_NOTCH_REFERENCE` (1512×982, notch 185×32) e o topo é calculado no
código: a janela nasce sempre colada na borda superior, sem opção de deslocar.

Por que vira um retângulo fantasma no Linux:

1. Não existe notch. A ilha não tem nada de útil para desenhar fora do macOS.
2. A janela é transparente, mas continua sendo uma janela: o Hyprland aplica
   sombra (e a moldura, se a configuração pedir) em volta de uma área vazia.

O fix adotado é desligar a ilha pela preferência do próprio app:

```bash
openbot-dock-ctl.sh island-off
```

O arquivo é `~/.config/OpenBot/openbot-dynamic-island-preference-v1.json`, lido
na inicialização — por isso o script reinicia o app quando o valor muda.
`island-on` apaga o arquivo e volta ao padrão do OpenBot.

### A tentativa que não deu certo

Um primeiro palpite foi pedir `no_border` e `no_shadow` na regra de janela.
`no_shadow` é válido, `no_border` **não**: ele só existe em `workspace_rule`. O
Hyprland recusa a chamada inteira com

```
hl.window_rule: unknown field 'no_border'
```

e a regra toda deixa de valer — inclusive o `pin`. O Omarchy mostra o erro numa
faixa no topo da tela, o que é fácil de confundir com mais um artefato.

`decorate = false` também é aceito, mas em teste controlado a janela transparente
passou a renderizar preta. Ficou fora.

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

Depois de uma falha do processo de GPU (`GPU process launch failed`), o app grava
`~/.config/OpenBot/gpu-crash.json`. Enquanto esse arquivo existir, o app sobe sem
aceleração e as janelas transparentes tendem a sair pretas. Apagar os dois
marcadores com o app fechado é o caminho para voltar ao renderizador normal.
