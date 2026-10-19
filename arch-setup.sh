#!/usr/bin/env bash
# Arch Setup : installateur post-install avec interface TUI (Textual)
#
#   Depuis le repo :  chmod +x arch-setup.sh && ./arch-setup.sh
#   Sans cloner :     bash <(curl -fsSL https://raw.githubusercontent.com/nath89-52/arch-setup/main/arch-setup.sh)
#
# Fichiers du projet : arch-setup.sh (ce script), apps.conf (ta liste d'apps), tui.py (l'interface)
# À lancer en utilisateur normal (PAS en root).

set -uo pipefail

REPO_RAW="https://raw.githubusercontent.com/nath89-52/arch-setup/main"

declare -a APPS=() DOTFILES=()
declare -A SELECTED=()
DOTFILE_CHOICE=-1
LOADED_COUNT=0
PY=python3
PRELOAD_FILE=""
PRELOAD_TMP=""

log() { echo -e "\n\033[1;34m==> $*\033[0m"; }
warn() { echo -e "\033[1;33m[!] $*\033[0m"; }

if [[ $EUID -eq 0 ]]; then
  echo "Ne lance pas ce script en root." >&2
  exit 1
fi

# ============================================================
# OÙ SONT LES FICHIERS ?
# ============================================================
# Lancé depuis le repo : on utilise les fichiers à côté du script.
# Lancé via "bash <(curl ...)" : on télécharge apps.conf et tui.py.

_SELF="${BASH_SOURCE[0]:-$0}"
_DIR=""
[[ -f "$_SELF" ]] && _DIR="$(cd "$(dirname "$_SELF")" && pwd)"

fetch_project_files() {
  command -v curl &>/dev/null || sudo pacman -Sy --noconfirm curl || exit 1
  SRC_DIR=$(mktemp -d)
  local f
  for f in apps.conf tui.py; do
    if ! curl -fsSL "$REPO_RAW/$f" -o "$SRC_DIR/$f"; then
      echo "Impossible de télécharger $f depuis $REPO_RAW" >&2
      exit 1
    fi
  done
}

if [[ -n "$_DIR" && -f "$_DIR/apps.conf" && -f "$_DIR/tui.py" ]]; then
  SRC_DIR="$_DIR"
else
  fetch_project_files
fi

# Sauvegarde de la sélection : à côté du script, sinon dans ton dossier perso
if [[ -n "$_DIR" && -w "$_DIR" ]]; then
  SELECTION_FILE="$_DIR/selection.conf"
else
  SELECTION_FILE="$HOME/selection.conf"
fi

# ============================================================
# DÉPENDANCES : Python + Textual
# ============================================================

ensure_textual() {
  if python3 -c "import textual" &>/dev/null; then return 0; fi
  log "Installation de Python et Textual (interface)"
  if sudo pacman -Syu --noconfirm --needed python python-textual && python3 -c "import textual" &>/dev/null; then
    return 0
  fi
  warn "python-textual indisponible via pacman, essai avec un environnement virtuel"
  local venv="$HOME/.cache/arch-setup/venv"
  python3 -m venv "$venv" && "$venv/bin/pip" install -q textual || return 1
  PY="$venv/bin/python"
}

# ============================================================
# LECTURE DE apps.conf ET DES SAUVEGARDES
# ============================================================

load_conf() {
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    line=${line%$'\r'}
    line="${line#"${line%%[![:space:]]*}"}"; line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    if [[ "$line" == @dotfiles\|* ]]; then
      DOTFILES+=("${line#@dotfiles|}")
    else
      APPS+=("$line")
    fi
  done < "$1"
}

# Lit un fichier de sélection et coche les apps correspondantes.
# Le fichier n'est jamais exécuté : on compare juste les noms de paquets à ta liste.
apply_selection_file() {
  local file="$1" line kind value i pkg label
  LOADED_COUNT=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line=${line%$'\r'}
    kind="${line%%:*}"; value="${line#*:}"
    case "$kind" in
      app)
        for i in "${!APPS[@]}"; do
          IFS='|' read -r _ _ _ pkg _ <<< "${APPS[$i]}"
          if [[ "$pkg" == "$value" ]]; then SELECTED[$i]=1; LOADED_COUNT=$((LOADED_COUNT + 1)); fi
        done ;;
      dotfiles)
        for i in "${!DOTFILES[@]}"; do
          label="${DOTFILES[$i]%%|*}"
          [[ "$label" == "$value" ]] && DOTFILE_CHOICE=$i
        done ;;
    esac
  done < "$file"
}

# Au lancement : propose de charger une sélection sauvegardée (chemin ou lien).
ask_preload() {
  local default="" prompt src
  [[ -f "$SELECTION_FILE" ]] && default="$SELECTION_FILE"
  echo
  if [[ -n "$default" ]]; then
    prompt="Sélection sauvegardée ? Chemin ou lien (Entrée = $default, n = ignorer) : "
  else
    prompt="Sélection sauvegardée à charger ? Chemin ou lien (Entrée = ignorer) : "
  fi
  read -r -p "$prompt" src || return 0
  src="${src#"${src%%[![:space:]]*}"}"; src="${src%"${src##*[![:space:]]}"}"
  [[ "$src" == [nN] || "$src" == [nN][oO][nN] ]] && return 0
  [[ -z "$src" ]] && src="$default"
  [[ -z "$src" ]] && return 0
  src="${src/#\~/$HOME}"

  if [[ "$src" =~ ^https?:// ]]; then
    command -v curl &>/dev/null || { warn "curl n'est pas installé, sauvegarde ignorée."; return 0; }
    PRELOAD_TMP=$(mktemp)
    if curl -fsL "$src" -o "$PRELOAD_TMP" 2>/dev/null; then
      PRELOAD_FILE="$PRELOAD_TMP"
    else
      warn "Impossible de télécharger : $src (sauvegarde ignorée)"
      rm -f "$PRELOAD_TMP"; PRELOAD_TMP=""
    fi
  elif [[ -f "$src" ]]; then
    PRELOAD_FILE="$src"
  else
    warn "Fichier introuvable : $src (sauvegarde ignorée)"
  fi
}

# ============================================================
# INSTALLATION
# ============================================================

enable_multilib_if_needed() {
  grep -q '^\[multilib\]' /etc/pacman.conf && return
  log "Activation du dépôt multilib (requis pour Steam)"
  sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
}

install_yay() {
  command -v yay &>/dev/null && return
  log "Installation de yay"
  local tmp; tmp=$(mktemp -d)
  git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin" || return 1
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm) || return 1
  rm -rf "$tmp"
}

run_install() {
  local PACMAN_LIST=() AUR_LIST=() FLATPAK_LIST=() i src pkg

  for i in $(printf '%s\n' "${!SELECTED[@]}" | sort -n); do
    IFS='|' read -r _ _ src pkg _ <<< "${APPS[$i]}"
    case "$src" in
      pacman)  PACMAN_LIST+=("$pkg") ;;
      aur)     AUR_LIST+=("$pkg") ;;
      flatpak) FLATPAK_LIST+=("$pkg") ;;
      *) warn "Source inconnue '$src' pour $pkg, ignoré" ;;
    esac
  done

  # Base
  log "Mise à jour du système + outils de base"
  sudo pacman -Syu --noconfirm --needed git base-devel curl wget || return 1

  # Steam => multilib
  for pkg in "${PACMAN_LIST[@]:-}"; do
    [[ "$pkg" == "steam" ]] && enable_multilib_if_needed && sudo pacman -Sy
  done

  # Pacman
  if (( ${#PACMAN_LIST[@]} > 0 )); then
    log "Paquets officiels : ${PACMAN_LIST[*]}"
    sudo pacman -S --noconfirm --needed "${PACMAN_LIST[@]}" || warn "Certains paquets pacman ont échoué"
  fi

  # AUR
  if (( ${#AUR_LIST[@]} > 0 )); then
    install_yay || { warn "yay n'a pas pu être installé, AUR ignoré"; AUR_LIST=(); }
  fi
  if (( ${#AUR_LIST[@]} > 0 )); then
    log "Paquets AUR : ${AUR_LIST[*]}"
    yay -S --noconfirm --needed "${AUR_LIST[@]}" || warn "Certains paquets AUR ont échoué"
  fi

  # Flatpak
  if (( ${#FLATPAK_LIST[@]} > 0 )); then
    log "Flatpak : ${FLATPAK_LIST[*]}"
    sudo pacman -S --noconfirm --needed flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub "${FLATPAK_LIST[@]}" || warn "Certains flatpaks ont échoué"
  fi

  # Dotfiles en dernier
  if (( DOTFILE_CHOICE >= 0 )); then
    IFS='|' read -r label url dir cmd <<< "${DOTFILES[$DOTFILE_CHOICE]}"
    log "Dotfiles : $label"
    local tmp; tmp=$(mktemp -d)
    if git clone "$url" "$tmp/$dir"; then
      (cd "$tmp/$dir" && eval "$cmd") || warn "La commande des dotfiles a échoué"
    else
      warn "Le clone des dotfiles a échoué"
    fi
    # on garde le dossier au cas où le setup y fait référence
    echo "Dossier des dotfiles : $tmp/$dir"
  fi

  log "Terminé ! Un reboot est conseillé."
}

# ============================================================
# MAIN
# ============================================================

main() {
  ensure_textual || { echo "Impossible d'installer Textual." >&2; exit 1; }
  load_conf "$SRC_DIR/apps.conf"
  ask_preload

  local result
  result=$(mktemp -u /tmp/arch-setup-result.XXXXXX)
  APPS_CONF="$SRC_DIR/apps.conf" SELECTION_FILE="$SELECTION_FILE" \
    PRELOAD_FILE="$PRELOAD_FILE" RESULT_FILE="$result" \
    "$PY" "$SRC_DIR/tui.py"
  [[ -n "$PRELOAD_TMP" ]] && rm -f "$PRELOAD_TMP"

  if [[ ! -s "$result" ]]; then
    echo "Installation annulée."
    exit 0
  fi
  apply_selection_file "$result"
  rm -f "$result"
  run_install
}

main
