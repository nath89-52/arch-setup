#!/usr/bin/env bash
# Installateur TUI post-install Arch Linux
# Usage : chmod +x arch-installer.sh && ./arch-installer.sh
# À lancer en utilisateur normal (PAS en root).

set -uo pipefail

# ============================================================
# CONFIG : modifie ces listes pour ajouter / retirer des trucs
# ============================================================

# Dotfiles (choix unique)
# Format : "Nom affiché|URL git|dossier cloné|commande à lancer dedans"
DOTFILES=(
  "Satoxyan - expressive-pC|https://github.com/Satoxyan/dots-hyprfork.git|dots-hyprfork|./setup install"
  # "Autre dotfiles|https://github.com/user/repo.git|repo|./install.sh"
)

# Apps
# Format : "Catégorie|Nom affiché|source (pacman/aur/flatpak)|nom du paquet"
APPS=(
  "Navigateurs|Firefox|pacman|firefox"
  "Navigateurs|Chromium|pacman|chromium"
  "Navigateurs|Zen Browser|aur|zen-browser-bin"
  "Navigateurs|Brave|aur|brave-bin"

  "Socials|Discord|pacman|discord"
  "Socials|Vesktop (Discord + Vencord)|aur|vesktop-bin"
  "Socials|Telegram|pacman|telegram-desktop"
  "Socials|Signal|pacman|signal-desktop"

  "Média|VLC|pacman|vlc"
  "Média|mpv|pacman|mpv"
  "Média|OBS Studio|pacman|obs-studio"
  "Média|GIMP|pacman|gimp"
  "Média|Kdenlive|pacman|kdenlive"
  "Média|Spotify|aur|spotify"

  "Jeux|Steam|pacman|steam"
  "Jeux|Lutris|pacman|lutris"
  "Jeux|Heroic Games Launcher|aur|heroic-games-launcher-bin"
  "Jeux|Prism Launcher (Minecraft)|pacman|prismlauncher"

  "Productivité|LibreOffice|pacman|libreoffice-fresh"
  "Productivité|Obsidian|pacman|obsidian"
  "Productivité|VS Code|aur|visual-studio-code-bin"
  "Productivité|Neovim|pacman|neovim"
  "Productivité|Bitwarden|pacman|bitwarden"
)

# ============================================================
# ÉTAT
# ============================================================

declare -A SELECTED=()      # index de APPS -> 1 si coché
DOTFILE_CHOICE=-1           # index de DOTFILES, -1 = aucun
CATEGORIES=()

for entry in "${APPS[@]}"; do
  cat="${entry%%|*}"
  found=0
  for c in "${CATEGORIES[@]:-}"; do [[ "$c" == "$cat" ]] && found=1; done
  (( found == 0 )) && CATEGORIES+=("$cat")
done

# ============================================================
# OUTILS
# ============================================================

log() { echo -e "\n\033[1;34m==> $*\033[0m"; }
warn() { echo -e "\033[1;33m[!] $*\033[0m"; }

if [[ $EUID -eq 0 ]]; then
  echo "Ne lance pas ce script en root." >&2
  exit 1
fi

if ! command -v whiptail &>/dev/null; then
  log "Installation de whiptail (libnewt)"
  sudo pacman -S --noconfirm --needed libnewt || exit 1
fi

count_selected() { echo "${#SELECTED[@]}"; }

# ============================================================
# MENUS
# ============================================================

menu_dotfiles() {
  local args=() i label choice
  args+=("none" "Aucun" "$([[ $DOTFILE_CHOICE -eq -1 ]] && echo ON || echo OFF)")
  for i in "${!DOTFILES[@]}"; do
    label="${DOTFILES[$i]%%|*}"
    args+=("$i" "$label" "$([[ $DOTFILE_CHOICE -eq $i ]] && echo ON || echo OFF)")
  done
  choice=$(whiptail --title "Dotfiles" --radiolist \
    "Un seul choix (espace pour sélectionner, entrée pour valider)" \
    16 70 8 "${args[@]}" 3>&1 1>&2 2>&3) || return
  if [[ "$choice" == "none" ]]; then DOTFILE_CHOICE=-1; else DOTFILE_CHOICE=$choice; fi
}

menu_category() {
  local cat="$1" args=() i name src status result
  for i in "${!APPS[@]}"; do
    IFS='|' read -r c name src _ <<< "${APPS[$i]}"
    [[ "$c" != "$cat" ]] && continue
    status=OFF; [[ -n "${SELECTED[$i]:-}" ]] && status=ON
    args+=("$i" "$name  [$src]" "$status")
  done
  result=$(whiptail --title "$cat" --checklist \
    "Espace = cocher / décocher, entrée = valider" \
    20 70 12 "${args[@]}" 3>&1 1>&2 2>&3) || return
  # on retire d'abord toute la catégorie, puis on remet ce qui est coché
  for i in "${!APPS[@]}"; do
    [[ "${APPS[$i]%%|*}" == "$cat" ]] && unset 'SELECTED[$i]'
  done
  result=${result//\"/}
  for i in $result; do SELECTED[$i]=1; done
}

menu_programmes() {
  while true; do
    local args=() cat n i choice
    for cat in "${CATEGORIES[@]}"; do
      n=0
      for i in "${!SELECTED[@]}"; do
        [[ "${APPS[$i]%%|*}" == "$cat" ]] && ((n++))
      done
      args+=("$cat" "($n sélectionné(s))")
    done
    args+=("retour" "Revenir au menu principal")
    choice=$(whiptail --title "Programmes" --menu "Choisis une catégorie" \
      18 60 10 "${args[@]}" 3>&1 1>&2 2>&3) || return
    [[ "$choice" == "retour" ]] && return
    menu_category "$choice"
  done
}

confirm_summary() {
  local txt="" i
  if (( DOTFILE_CHOICE >= 0 )); then
    txt+="Dotfiles : ${DOTFILES[$DOTFILE_CHOICE]%%|*}\n\n"
  else
    txt+="Dotfiles : aucun\n\n"
  fi
  txt+="Programmes :\n"
  if (( ${#SELECTED[@]} == 0 )); then
    txt+="  (aucun)\n"
  else
    for i in $(printf '%s\n' "${!SELECTED[@]}" | sort -n); do
      IFS='|' read -r c name src pkg <<< "${APPS[$i]}"
      txt+="  - $name ($src)\n"
    done
  fi
  whiptail --title "Résumé" --yesno "$txt\nLancer l'installation ?" 24 70
}

main_menu() {
  local dot_label choice
  while true; do
    if (( DOTFILE_CHOICE >= 0 )); then
      dot_label="${DOTFILES[$DOTFILE_CHOICE]%%|*}"
    else
      dot_label="aucun"
    fi
    choice=$(whiptail --title "Arch post-install" --menu "Que veux-tu installer ?" \
      16 70 4 \
      1 "Dotfiles : $dot_label" \
      2 "Programmes : $(count_selected) sélectionné(s)" \
      3 "Lancer l'installation" \
      4 "Quitter" 3>&1 1>&2 2>&3) || exit 0
    case "$choice" in
      1) menu_dotfiles ;;
      2) menu_programmes ;;
      3) confirm_summary && return ;;
      4) exit 0 ;;
    esac
  done
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
    IFS='|' read -r _ _ src pkg <<< "${APPS[$i]}"
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

main_menu
run_install
