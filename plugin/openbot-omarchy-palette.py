#!/usr/bin/env python3
"""Gera a paleta "Omarchy" do OpenBot a partir do tema atual do Omarchy.

O OpenBot vigia a pasta ~/.config/OpenBot/themes/ e aplica uma paleta alterada sem reiniciar.
Este script lê as cores do tema atual (colors.toml) e grava themes/omarchy.json no formato que o
OpenBot aceita: nome, claro/escuro e 12 cores #rrggbb. A gravação é atômica (temporário + rename).
Se faltar uma cor ou alguma for inválida, nada é gravado e a paleta anterior continua.

Uso: openbot-omarchy-palette.py  (sem argumentos)
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


def pick(theme, *keys):
    """A primeira cor válida entre as chaves, na ordem dada."""
    for key in keys:
        value = theme.get(key)
        if isinstance(value, str) and HEX.match(value):
            return value.lower()
    raise KeyError(" / ".join(keys))


def theme_name():
    try:
        name = subprocess.run(["omarchy-theme-current"], capture_output=True, text=True, timeout=5).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        name = ""
    return f"Omarchy · {name}"[:64] if name else "Omarchy"


def build(theme):
    background = pick(theme, "background")
    mode = theme.get("mode")
    if mode not in ("light", "dark"):
        mode = "light" if luminance(background) > 0.5 else "dark"
    accent = pick(theme, "accent", "blue")
    # O texto sobre o accent: o lado (fundo escuro ou texto claro) com mais contraste.
    on_accent = max(
        (pick(theme, "darker_background", "dark_background", "background"), pick(theme, "bright_foreground", "foreground")),
        key=lambda c: contrast(c, accent),
    )
    return {
        "name": theme_name(),
        "appearance": mode,
        "colors": {
            "canvas": background,
            "frame": pick(theme, "dark_background", "background"),
            "sidebar": pick(theme, "dark_background", "background"),
            "surface": pick(theme, "lighter_background", "selection", "background"),
            "text": pick(theme, "foreground"),
            "textMuted": pick(theme, "muted", "dark_foreground", "foreground"),
            "border": pick(theme, "selection", "lighter_background", "muted"),
            "accent": accent,
            "accentForeground": on_accent,
            "success": pick(theme, "green", "bright_green"),
            "warning": pick(theme, "yellow", "bright_yellow"),
            "danger": pick(theme, "red", "bright_red"),
        },
    }


def main():
    try:
        with open(COLORS, "rb") as f:
            palette = build(tomllib.load(f))
    except FileNotFoundError:
        sys.exit(f"tema do Omarchy não encontrado: {COLORS}")
    except (tomllib.TOMLDecodeError, KeyError) as e:
        sys.exit(f"cores do tema inválidas ou ausentes ({e}); a paleta anterior foi mantida")

    os.makedirs(OUT_DIR, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=OUT_DIR, prefix=".omarchy.", suffix=".tmp")
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(palette, f, indent=2)
            f.write("\n")
        os.chmod(tmp, 0o644)
        os.replace(tmp, OUT)
    except BaseException:
        os.unlink(tmp)
        raise
    print(f"paleta={palette['name']} modo={palette['appearance']} -> {OUT}")


if __name__ == "__main__":
    main()
