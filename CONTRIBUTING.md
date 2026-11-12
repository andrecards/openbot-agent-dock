# Como contribuir

Projeto pessoal, mas com regras claras para não virar bagunça.

## Fluxo

1. Crie uma branch a partir de `main` (`feat/`, `fix/`, `docs/`).
2. Faça commits pequenos e com mensagem no padrão abaixo.
3. Teste **no Omarchy/Hyprland real** antes de abrir PR: o plugin mexe em
   janelas, barra e no app do OpenBot — não dá para validar só lendo o QML.
4. Abra PR descrevendo o comportamento antes e depois.

## Mensagens de commit

Conventional Commits, em português:

```
tipo(escopo): resumo no imperativo

Corpo opcional explicando o porquê, não o quê.
```

Tipos usados: `feat`, `fix`, `docs`, `build`, `chore`, `refactor`.

## Checklist de teste

```bash
omarchy plugin validate ~/.config/omarchy/plugins/io.github.andrecards.openbot-dock
~/.config/omarchy/plugins/io.github.andrecards.openbot-dock/openbot-dock-ctl.sh status
omarchy restart shell
```

- Ícone aparece na barra e muda de cor nos três modos (preto, blur,
  transparente).
- Painel abre e os três botões respondem.
- Dock desliza ao encostar o ponteiro na borda direita e recolhe ao afastar.
- Dock continua visível ao trocar de workspace.

## Estilo de código

- QML: seguir o padrão do Omarchy Shell (`qs.Ui`, `qs.Commons`), sem
  dependências externas.
- Shell: `set -uo pipefail`, `command -v` antes de usar binário, nada de `eval`.
- Textos de interface em `i18n/`, sempre em inglês e português.
- Nada de arquivo temporário na raiz: use `.scratchpad/`.
