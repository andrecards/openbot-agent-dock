#!/usr/bin/env bash
# Instala (ou remove) o widget OpenBot Dock no Omarchy Shell.
#
# O que faz:
#   1. copia o plugin para ~/.config/omarchy/plugins/io.github.andrecards.openbot-dock
#   2. instala a regra do Hyprland em ~/.config/hypr/openbot-dock.lua
#   3. garante o require("hypr.openbot-dock") no hyprland.lua (idempotente)
#   4. instala o gancho de tema do Omarchy (paleta "Omarchy" do OpenBot)
#   5. habilita o widget na seção direita da barra
#   6. reinicia o shell
#
# Uso:
#   ./install.sh              instala
#   ./install.sh --uninstall  remove plugin, regra e widget da barra
#   ./install.sh --no-restart instala sem reiniciar o shell

set -uo pipefail

PLUGIN_ID="io.github.andrecards.openbot-dock"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
PLUGIN_DIR="$CONFIG/omarchy/plugins/$PLUGIN_ID"
HYPR_DIR="$CONFIG/hypr"
RULE_FILE="$HYPR_DIR/openbot-dock.lua"
HYPR_CONFIG="$HYPR_DIR/hyprland.lua"
REQUIRE_LINE='require("hypr.openbot-dock")'
HOOK_FILE="$CONFIG/omarchy/hooks/theme-set.d/openbot-palette"

UNINSTALL=0
RESTART=1

for arg in "$@"; do
  case "$arg" in
    --uninstall) UNINSTALL=1 ;;
    --no-restart) RESTART=0 ;;
    -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "argumento desconhecido: $arg" >&2; exit 2 ;;
  esac
done

if [[ $UNINSTALL -eq 0 ]]; then
  command -v hyprctl >/dev/null || { echo "hyprctl não encontrado: isso é um plugin de Hyprland." >&2; exit 1; }
  command -v jq >/dev/null || echo "aviso: jq não encontrado; o script de controle depende dele." >&2
  command -v omarchy >/dev/null || { echo "omarchy não encontrado: instale o Omarchy Shell antes." >&2; exit 1; }
fi

if [[ $UNINSTALL -eq 1 ]]; then
  echo "→ desabilitando o widget na barra"
  omarchy plugin disable "$PLUGIN_ID" >/dev/null 2>&1 || true
  omarchy bar remove "$PLUGIN_ID" >/dev/null 2>&1 || true

  echo "→ removendo o plugin"
  rm -rf "$PLUGIN_DIR"

  echo "→ removendo o gancho de tema"
  rm -f "$HOOK_FILE"

  echo "→ removendo a regra do Hyprland"
  rm -f "$RULE_FILE"
  if [[ -f $HYPR_CONFIG ]]; then
    grep -vF -e "$REQUIRE_LINE" -e "-- Dock de agentes do OpenBot: fixo na borda direita, acima das janelas." \
      "$HYPR_CONFIG" > "$HYPR_CONFIG.tmp" && mv "$HYPR_CONFIG.tmp" "$HYPR_CONFIG"
    # não deixa linhas em branco sobrando no fim do arquivo
    printf '%s\n' "$(cat "$HYPR_CONFIG")" > "$HYPR_CONFIG.tmp" && mv "$HYPR_CONFIG.tmp" "$HYPR_CONFIG"
  fi

  hyprctl reload >/dev/null 2>&1 || true
  echo "Removido. Reinicie o shell para sumir da barra: omarchy restart shell"
  exit 0
fi

echo "→ instalando o plugin em $PLUGIN_DIR"
mkdir -p "$PLUGIN_DIR"
for item in manifest.json Widget.qml openbot-dock-ctl.sh openbot-omarchy-palette.py i18n icons; do
  cp -a "$ROOT/$item" "$PLUGIN_DIR/"
done
chmod +x "$PLUGIN_DIR/openbot-dock-ctl.sh" "$PLUGIN_DIR/openbot-omarchy-palette.py"

echo "→ instalando o gancho de tema em $HOOK_FILE"
mkdir -p "$(dirname "$HOOK_FILE")"
cp -a "$ROOT/hooks/theme-set.d/openbot-palette" "$HOOK_FILE"
chmod +x "$HOOK_FILE"
python3 -I "$PLUGIN_DIR/openbot-omarchy-palette.py" >/dev/null 2>&1 || echo "  aviso: não deu para gerar a paleta do Omarchy agora"

echo "→ instalando a regra do Hyprland em $RULE_FILE"
mkdir -p "$HYPR_DIR"
cp -a "$ROOT/hypr/openbot-dock.lua" "$RULE_FILE"

if [[ -f $HYPR_CONFIG ]] && ! grep -qF "$REQUIRE_LINE" "$HYPR_CONFIG"; then
  printf '\n-- Dock de agentes do OpenBot: fixo na borda direita, acima das janelas.\n%s\n' "$REQUIRE_LINE" >> "$HYPR_CONFIG"
  echo "  require adicionado em hyprland.lua"
else
  echo "  require já presente em hyprland.lua"
fi

echo "→ habilitando o widget na barra"
omarchy plugin enable "$PLUGIN_ID" --section right --after omarchy.agents >/dev/null 2>&1 || \
  omarchy plugin enable "$PLUGIN_ID" >/dev/null 2>&1 || true

hyprctl reload >/dev/null 2>&1 || true

if [[ $RESTART -eq 1 ]]; then
  echo "→ reiniciando o shell"
  omarchy restart shell >/dev/null 2>&1 || true
fi

echo
echo "Pronto."
echo "  status: $PLUGIN_DIR/openbot-dock-ctl.sh status"
echo "  dock:   $PLUGIN_DIR/openbot-dock-ctl.sh dock-on"
echo
echo "O auto-hide do dock é opção do OpenBot (Configurações → Agent Dock)."
