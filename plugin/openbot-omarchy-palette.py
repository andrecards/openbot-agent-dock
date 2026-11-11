#!/usr/bin/env python3
"""Gera a paleta "Omarchy" do OpenBot a partir do tema atual do Omarchy.

Aceita os dois formatos de colors.toml do Omarchy: o atual (muted, selection, red...) e o antigo
(color0..color15): nele, os tons neutros que faltam são calculados do fundo e do texto.

O OpenBot vigia a pasta ~/.config/OpenBot/themes/ e aplica uma paleta alterada sem reiniciar.
Este script lê as cores do tema atual (colors.toml) e grava themes/omarchy.json no formato que o
OpenBot aceita: nome, claro/escuro e 12 cores #rrggbb. A gravação é atômica (temporário + rename).
Se faltar uma cor ou alguma for inválida, nada é gravado e a paleta anterior continua.

Uso: openbot-omarchy-palette.py [colors.toml] [saída.json]
     Sem argumentos: tema atual do Omarchy -> ~/.config/OpenBot/themes/omarchy.json.
     Os argumentos servem para testar outro tema sem trocar o tema do sistema.
"""

import json
import os
import re
import subprocess
import sys
import tempfile
import tomllib

HOME = os.path.expanduser("~")
COLORS = os.path.join(HOME, ".local/state/omarchy/current/theme/colors.toml")
CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.join(HOME, ".config")
OUT_DIR = os.path.join(CONFIG, "OpenBot", "themes")
OUT = os.path.join(OUT_DIR, "omarchy.json")
HEX = re.compile(r"^#[0-9a-fA-F]{6}$")


def luminance(hex_color):
    r, g, b = (int(hex_color[i : i + 2], 16) / 255 for i in (1, 3, 5))
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in (r, g, b)]
    return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]


def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def pick(theme, *keys, default=None):
    """A primeira cor válida entre as chaves, na ordem dada; senão `default` (ou erro)."""
    for key in keys:
        value = theme.get(key)
        if isinstance(value, str) and HEX.match(value):
            return value.lower()
    if default is not None:
        return default
    raise KeyError(" / ".join(keys))


def mix(a, b, t):
    """Cor entre `a` e `b`: t=0 é `a`, t=1 é `b`."""
    ca = [int(a[i : i + 2], 16) for i in (1, 3, 5)]
    cb = [int(b[i : i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{round(x + (y - x) * t):02x}" for x, y in zip(ca, cb))


def theme_name(colors_path):
    if colors_path != COLORS:
        return f"Omarchy · {os.path.basename(os.path.dirname(colors_path))}"[:64]
    try:
        name = subprocess.run(["omarchy-theme-current"], capture_output=True, text=True, timeout=5).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        name = ""
    return f"Omarchy · {name}"[:64] if name else "Omarchy"


def build(theme, colors_path):
    background = pick(theme, "background")
    foreground = pick(theme, "foreground")
    mode = theme.get("mode")
    if mode not in ("light", "dark"):
        mode = "light" if luminance(background) > 0.5 else "dark"
    # Temas no formato antigo (color0..15) não têm tons neutros próprios: as cores ANSI deles podem ser
    # fortes. Os neutros que faltam saem da mistura do fundo com o texto, que funciona em qualquer tema.
    shade = mix(background, "#000000", 0.25 if mode == "dark" else 0.04)
    accent = pick(theme, "accent", "blue", "color4")
    # O texto sobre o accent: o lado (fundo escuro ou texto claro) com mais contraste.
    on_accent = max(
        (pick(theme, "darker_background", "dark_background", "background"), pick(theme, "bright_foreground", "foreground")),
        key=lambda c: contrast(c, accent),
    )
    return {
        "name": theme_name(colors_path),
        "appearance": mode,
        "colors": {
            "canvas": background,
            "frame": pick(theme, "dark_background", default=shade),
            "sidebar": pick(theme, "dark_background", default=shade),
            "surface": pick(theme, "lighter_background", "selection", default=mix(background, foreground, 0.08)),
            "text": foreground,
            "textMuted": pick(theme, "muted", "dark_foreground", default=mix(foreground, background, 0.4)),
            "border": pick(theme, "selection", "lighter_background", default=mix(background, foreground, 0.18)),
            "accent": accent,
            "accentForeground": on_accent,
            "success": pick(theme, "green", "bright_green", "color2", "color10"),
            "warning": pick(theme, "yellow", "bright_yellow", "color3", "color11"),
            "danger": pick(theme, "red", "bright_red", "color1", "color9"),
        },
    }


def main():
    colors_path = sys.argv[1] if len(sys.argv) > 1 else COLORS
    out = sys.argv[2] if len(sys.argv) > 2 else OUT
    try:
        with open(colors_path, "rb") as f:
            palette = build(tomllib.load(f), colors_path)
    except FileNotFoundError:
        sys.exit(f"tema do Omarchy não encontrado: {colors_path}")
    except (tomllib.TOMLDecodeError, KeyError) as e:
        sys.exit(f"cores do tema inválidas ou ausentes ({e}); a paleta anterior foi mantida")

    out_dir = os.path.dirname(out)
    os.makedirs(out_dir, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=out_dir, prefix=".omarchy.", suffix=".tmp")
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(palette, f, indent=2)
            f.write("\n")
        os.chmod(tmp, 0o644)
        os.replace(tmp, out)
    except BaseException:
        os.unlink(tmp)
        raise
    print(f"paleta={palette['name']} modo={palette['appearance']} -> {out}")


if __name__ == "__main__":
    main()
