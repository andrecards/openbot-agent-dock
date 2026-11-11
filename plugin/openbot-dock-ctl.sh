#!/usr/bin/env bash
# Controla o OpenBot e o Agent Dock dele a partir do widget da barra.
#
# O dock do OpenBot só flutua sobre as outras janelas quando o app inicia em
# XWayland. O próprio OpenBot guarda essa escolha no arquivo
# ~/.config/OpenBot/agent-dock-xwayland: existindo o arquivo, todo início em
# Wayland relança o app com --ozone-platform=x11. Este script liga e desliga
# esse marcador e reinicia o app do jeito certo.
#
# Uso: openbot-dock-ctl.sh status|open|dock-on|dock-off|restart

set -uo pipefail

APP_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/OpenBot"
MARKER="$APP_DIR/agent-dock-xwayland"
IMAGES_DIR="$HOME/.local/share/AppImages"

# O AppImage mais recente de verdade (o wrapper quebrado de 600 bytes fica fora).
find_appimage() {
  local found
  found=$(find "$IMAGES_DIR" -maxdepth 1 -type f -name 'OpenBot-*-x86_64.AppImage' -size +20M \
            -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  if [[ -n $found && -x $found ]]; then
    printf '%s\n' "$found"
    return 0
  fi
  # Qualquer outro nome que o usuário tenha posto na pasta.
  found=$(find "$IMAGES_DIR" -maxdepth 1 -type f -iname 'openbot*.AppImage' -size +20M \
            -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  [[ -n $found && -x $found ]] || return 1
  printf '%s\n' "$found"
}

app_running() {
  pgrep -x openbot >/dev/null 2>&1
}

app_version() {
  local img=${1:-}
  [[ -n $img ]] || return 0
  basename "$img" | sed -nE 's/^OpenBot-([0-9][0-9.]*)-x86_64\.AppImage$/\1/p'
}

above_apps() {
  [[ -f $MARKER ]] && echo 1 || echo 0
}

launch_app() {
  local img=$1
  shift
  # setsid: o app não pode morrer junto com o processo que o widget disparou.
  setsid "$img" "$@" >/dev/null 2>&1 < /dev/null &
}

stop_app() {
  app_running || return 0
  pkill -x openbot 2>/dev/null
  local i
  for i in $(seq 1 60); do
    app_running || break
    sleep 0.1
  done
  if app_running; then
    pkill -9 -x openbot 2>/dev/null
    sleep 0.2
  fi
  # Um encerramento à força deixa as travas do Electron apontando para um PID morto.
  rm -f "$APP_DIR"/Singleton* 2>/dev/null
}

restart_app() {
  local img
  img=$(find_appimage) || { echo "appimage=missing"; exit 1; }
  stop_app
  sleep 0.3
  if [[ -f $MARKER ]]; then
    launch_app "$img" --ozone-platform=x11
  else
    launch_app "$img"
  fi
}

focus_app() {
  local address
  # A janela principal é a que NÃO flutua; as flutuantes são o dock e o painel.
  address=$(hyprctl clients -j 2>/dev/null \
    | jq -r '.[] | select(.class == "openbot" and (.floating | not)) | .address' 2>/dev/null \
    | head -1)
  if [[ -n $address ]]; then
    # Hyprland 0.56+ usa config Lua: dispatcher é expressão, não string antiga.
    hyprctl dispatch "hl.dsp.window.focus({window=\"address:$address\"})" >/dev/null 2>&1
    return 0
  fi
  return 1
}

status() {
  local img version
  img=$(find_appimage) || img=""
  version=$(app_version "$img")
  echo "running=$(app_running && echo 1 || echo 0)"
  echo "above_apps=$(above_apps)"
  echo "version=$version"
  echo "appimage=$img"
}

case "${1:-status}" in
  status)
    status
    ;;
  open)
    if app_running; then
      focus_app || true
    else
      img=$(find_appimage) || { echo "OpenBot não encontrado em $IMAGES_DIR"; exit 1; }
      if [[ -f $MARKER ]]; then
        launch_app "$img" --ozone-platform=x11
      else
        launch_app "$img"
      fi
    fi
    ;;
  dock-on)
    mkdir -p "$APP_DIR"
    : > "$MARKER"
    restart_app
    status
    ;;
  dock-off)
    rm -f "$MARKER"
    if app_running; then
      restart_app
    fi
    status
    ;;
  restart)
    restart_app
    status
    ;;
  *)
    echo "uso: $(basename "$0") status|open|dock-on|dock-off|restart" >&2
    exit 2
    ;;
esac
