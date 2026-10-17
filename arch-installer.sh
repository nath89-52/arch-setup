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
)

# Apps
# Format : "Catégorie|Nom affiché|source (pacman/aur/flatpak)|nom du paquet|description"
# La description s'affiche en bas de l'écran quand tu survoles l'app.
APPS=(
  "Navigateurs|Firefox|pacman|firefox|Navigateur web open source, rapide et respectueux de la vie privée"
  "Navigateurs|Librewolf|pacman|librewolf|Ce projet est une version personnalisée et indépendante de Firefox, avec pour principaux objectifs la confidentialité, la sécurité et la liberté de l'utilisateur."
  "Navigateurs|Chromium|pacman|chromium|Version open source de Chrome, très compatible avec les sites web"
  "Navigateurs|Zen Browser|aur|zen-browser-bin|Navigateur basé sur Firefox, orienté design moderne et productivité"
  "Navigateurs|Brave|aur|brave-bin|Navigateur basé sur Chromium avec bloqueur de pubs intégré"
  "Navigateurs|Vivaldi|pacman|vivaldi|Navigateur propriétaire basé sur Chromium, très personnalisable et riche en fonctionnalités"
  "Navigateurs|Floorp|aur|floorp-bin|Navigateur basé sur Firefox, axé sur la personnalisation, la productivité et la confidentialité"
  "Navigateurs|Falkon|pacman|falkon|Navigateur léger basé sur QtWebEngine, avec une interface simple et une bonne intégration KDE"
  "Navigateurs|Google Chrome|aur|google-chrome|Navigateur de Google basé sur Chromium, excellente compatibilité web et synchronisation avec un compte Google"
  "Navigateurs|Microsoft Edge|aur|microsoft-edge-stable-bin|Navigateur basé sur Chromium, intégrant les services Microsoft et des fonctions de productivité"
  "Navigateurs|Opera|aur|opera|Navigateur basé sur Chromium avec VPN intégré au navigateur, bloqueur de publicités et barre latérale"
  "Navigateurs|Opera GX|aur|opera-gx|Navigateur orienté gaming avec personnalisation poussée et outils de gestion des ressources"
  "Navigateurs|Tor Browser|aur|tor-browser-bin|Navigateur basé sur Firefox qui privilégie l'anonymat en faisant transiter le trafic par le réseau Tor"
 
  "Fichiers|Dolphin|pacman|dolphin|Gestionnaire de fichiers avancé de KDE, avec onglets, panneaux et accès réseau"
  "Fichiers|Thunar|pacman|thunar|Gestionnaire de fichiers léger, rapide et adapté aux environnements minimalistes"
  "Fichiers|Yazi|pacman|yazi|Gestionnaire de fichiers en terminal avec aperçu des images et navigation rapide"
  "Fichiers|Filelight|pacman|filelight|Visualise l'espace disque utilisé avec des graphiques circulaires"
  "Fichiers|Baobab|pacman|baobab|Analyse l'utilisation du stockage avec une interface graphique simple"
  "Fichiers|Ark|pacman|ark|Gestionnaire graphique d'archives pour créer et extraire des fichiers compressés"
  "Fichiers|7-Zip|pacman|7zip|Outil de compression et d'extraction prenant en charge de nombreux formats"
  "Fichiers|KDE Connect|pacman|kdeconnect|Connecte ton téléphone Android au PC pour partager des fichiers, recevoir des notifications et contrôler certains appareils"
  "Fichiers|LocalSend|aur|localsend-bin|Transfert de fichiers entre appareils sur le réseau local, sans compte ni serveur cloud"
 
  "Socials|Discord|pacman|discord|Chat vocal et textuel pour les serveurs et les potes"
  "Socials|Vesktop (Discord + Vencord)|aur|vesktop-bin|Client Discord alternatif avec Vencord intégré (plugins, thèmes)"
  "Socials|Telegram|pacman|telegram-desktop|Messagerie rapide avec groupes, canaux et stickers"
  "Socials|Signal|pacman|signal-desktop|Messagerie chiffrée de bout en bout, centrée sur la vie privée"
 
  "Media|VLC|pacman|vlc|Lecteur vidéo et audio qui lit presque tous les formats"
  "Media|mpv|pacman|mpv|Lecteur vidéo minimaliste et léger"
  "Media|viewnior|pacman|viewnior|Visionneur d'images rapide et élégant"
  "Media|OBS Studio|pacman|obs-studio|Enregistrement d'écran et streaming en direct"
  "Media|GPU Screen Recorder|flatpak|com.dec05eba.gpu_screen_recorder|Enregistrement d'écran léger qui utilise le GPU, idéal pour les clips de jeu (Nvidia shadowplay)"
  "Media|GIMP|pacman|gimp|Retouche d'images, l'alternative libre à Photoshop"
  "Media|Kdenlive|pacman|kdenlive|Logiciel de montage vidéo complet"
  "Media|Spotify|aur|spotify|Streaming musical (client officiel)"
  "Media|Sonora|aur|sonora-bin|Spotify (besoin de premium); apple music; youtube music; subsonic et deezer dans 1 seul app codee en rust"
  "Media|Krita|pacman|krita|Logiciel de dessin numérique et de peinture pour illustrations"
  "Media|Inkscape|pacman|inkscape|Création et modification de graphiques vectoriels au format SVG"
  "Media|Darktable|pacman|darktable|Développement photo RAW et gestion des retouches non destructives"
  "Media|RawTherapee|pacman|rawtherapee|Développement et traitement avancé des photos RAW, notamment NEF"
  "Media|Upscayl|aur|upscayl-bin|Agrandit les images grâce à des modèles d'intelligence artificielle"
  "Media|Audacity|pacman|audacity|Enregistrement, découpage et traitement audio"
  "Media|Tenacity|aur|tenacity|Éditeur audio libre pour enregistrer et modifier des pistes sonores"
  "Media|LosslessCut|aur|losslesscut-bin|Découpe des vidéos et fichiers audio sans réencodage dans les cas compatibles"
  "Media|HandBrake|pacman|handbrake|Convertit et compresse les vidéos avec de nombreux réglages"
  "Media|Jellyfin Media Player|aur|jellyfin-media-player|Client de lecture pour accéder à un serveur multimédia Jellyfin"
 
  "Jeux|Steam|pacman|steam|Plateforme de jeux (active le dépôt multilib automatiquement)"
  "Jeux|Lutris|pacman|lutris|Gestionnaire de jeux pour Wine, émulateurs et autres launchers"
  "Jeux|Heroic Games Launcher|aur|heroic-games-launcher-bin|Launcher pour les jeux Epic Games, GOG et Amazon"
  "Jeux|Prism Launcher (Minecraft)|pacman|prismlauncher|Launcher Minecraft avec gestion de plusieurs instances et mods"
  "Jeux|Sober|flatpak|sober|Port de la version mobile de roblox"
  "Jeux|ProtonUp-Qt|aur|protonup-qt|Installe et gère des versions personnalisées de Proton-GE et de Wine-GE"
  "Jeux|MangoHud|pacman|mangohud|Affiche les FPS, l'utilisation CPU/GPU et les frametimes en jeu"
  "Jeux|GOverlay|pacman|goverlay|Configure graphiquement MangoHud et certaines options Vulkan"
  "Jeux|Gamescope|pacman|gamescope|Compositeur orienté gaming permettant notamment de gérer la résolution et la mise à l'échelle"
  "Jeux|CoreCtrl|pacman|corectrl|Contrôle graphique des performances et paramètres matériels pris en charge"
  "Jeux|AntiMicroX|pacman|antimicrox|Associe les boutons d'une manette à des touches et commandes"
  "Jeux|Discord RPC Maker|aur|discord-rpc-maker|Outil communautaire pour personnaliser certaines activités Rich Presence Discord"
 
  "Productivité|LibreOffice|pacman|libreoffice-fresh|Suite bureautique : texte, tableur, présentations"
  "Productivité|Obsidian|pacman|obsidian|Prise de notes en Markdown avec liens entre les notes"
  "Productivité|VS Code|aur|visual-studio-code-bin|Éditeur de code populaire avec des milliers d'extensions"
  "Productivité|MousePad|pacman|mousepad|Editeur de text"
  "Productivité|Neovim|pacman|neovim|Éditeur de texte en terminal, ultra configurable"
  "Productivité|Bitwarden|pacman|bitwarden|Gestionnaire de mots de passe"
 
  "Outils|DiskTree|aur|disktree-bin|"
  "Outils|htop|pacman|htop|Gestionaire de taches dans le terminal"
  "Outils|btop|pacman|btop|Gestionaire de taches dans le terminal"
  "Outils|unzip|pacman|unzip|Permet de unzip des fichiers"
  "Outils|Gearlever|flatpak|it.mijorus.gearlever|Permet de gere automatiquement les app images"
  "Outils|Mission Center|pacman|mission-center|Moniteur graphique des processus, du CPU, de la mémoire et du réseau"
  "Outils|Glances|pacman|glances|Surveille les ressources système dans le terminal avec de nombreuses statistiques"
  "Outils|Fastfetch|pacman|fastfetch|Affiche les informations système avec un résumé visuel dans le terminal"
  "Outils|Dust|pacman|dust|Visualise l'espace occupé par les dossiers directement dans le terminal"
  "Outils|Duf|pacman|duf|Affiche clairement les partitions, leur espace libre et leur occupation"
  "Outils|ncdu|pacman|ncdu|Analyse l'espace disque et permet de naviguer dans les dossiers volumineux"
  "Outils|btrfs-assistant|aur|btrfs-assistant|Interface graphique pour gérer les systèmes de fichiers Btrfs et leurs snapshots"
  "Outils|GParted|pacman|gparted|Outil graphique de partitionnement et de gestion des disques"
  "Outils|Pavucontrol|pacman|pavucontrol|Configure les entrées, sorties et volumes audio"
  "Outils|NetworkManager Applet|pacman|network-manager-applet|Applet graphique pour gérer les connexions réseau"
  "Outils|Overskride|aur|overskride|Interface graphique pour gérer les appareils Bluetooth sous Linux"
  "Outils|Pacseek|aur|pacseek|Interface en terminal pour rechercher, installer et supprimer des paquets Arch"
 
  "Bureau|Wofi|pacman|wofi|Lanceur d'applications pour Wayland, compatible avec Hyprland"
  "Bureau|Fuzzel|pacman|fuzzel|Lanceur d'applications Wayland minimaliste et rapide"
  "Bureau|Waybar|pacman|waybar|Barre système personnalisable pour Wayland avec modules et indicateurs"
  "Bureau|SwayNC|pacman|swaync|Centre de notifications et panneau de contrôle pour Wayland"
  "Bureau|Walker|aur|walker|Lanceur d'applications extensible avec recherche et extensions"
  "Bureau| nwg-look|pacman|nwg-look|Configure les thèmes GTK, les icônes et les curseurs sous Wayland"
  "Bureau|qt6ct|pacman|qt6ct|Configure l'apparence des applications Qt indépendamment de KDE Plasma"
 
  "Développement|VSCodium|flatpak|com.vscodium.codium|Éditeur de code open source sans la distribution officielle de Microsoft"
  "Développement|Zed|aur|zed|Éditeur de code moderne et rapide avec fonctionnalités collaboratives et IA"
  "Développement|GitHub CLI|pacman|github-cli|Gère les dépôts, issues et pull requests GitHub depuis le terminal"
  "Développement|GitHub Desktop|aur|github-desktop-bin|Interface graphique pour gérer les commits, branches et dépôts Git"
  "Développement|GitKraken|aur|gitkraken|Client graphique Git avec visualisation des branches et historique"
  "Développement|DBeaver|aur|dbeaver-bin|Interface graphique pour explorer et administrer de nombreuses bases de données"
  "Développement|Docker|pacman|docker|Plateforme pour exécuter et gérer des applications dans des conteneurs"
  "Développement|Docker Compose|pacman|docker-compose|Décrit et gère plusieurs conteneurs avec un fichier YAML"
  "Développement|Python|pacman|python|Interpréteur Python pour exécuter et développer des scripts"
  "Développement|Pytest|pacman|python-pytest|Framework de tests pour vérifier automatiquement le fonctionnement du code Python"
  "Développement|Visual Studio Code Insiders|aur|visual-studio-code-insiders-bin|Version de développement de VS Code pour tester les nouveautés"
  
)

# ============================================================
# ÉTAT
# ============================================================

declare -A SELECTED=()      # index de APPS -> 1 si coché
DOTFILE_CHOICE=-1           # index de DOTFILES, -1 = aucun
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELECTION_FILE="$SCRIPT_DIR/selection.conf"   # sauvegarde de ta sélection
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

if ! command -v dialog &>/dev/null; then
  log "Installation de dialog"
  sudo pacman -S --noconfirm --needed dialog || exit 1
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
  choice=$(dialog --title "Dotfiles" --radiolist \
    "Un seul choix (espace pour sélectionner, entrée pour valider)" \
    16 70 8 "${args[@]}" 3>&1 1>&2 2>&3) || return
  if [[ "$choice" == "none" ]]; then DOTFILE_CHOICE=-1; else DOTFILE_CHOICE=$choice; fi
}

menu_category() {
  local cat="$1" args=() i c name src pkg desc status result
  for i in "${!APPS[@]}"; do
    IFS='|' read -r c name src pkg desc <<< "${APPS[$i]}"
    [[ "$c" != "$cat" ]] && continue
    status=OFF; [[ -n "${SELECTED[$i]:-}" ]] && status=ON
    args+=("$i" "$name  [$src]" "$status" "${desc:-Pas de description}")
  done
  result=$(dialog --title "$cat" --item-help --checklist \
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
    choice=$(dialog --title "Programmes" --menu "Choisis une catégorie" \
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
      IFS='|' read -r c name src pkg _ <<< "${APPS[$i]}"
      txt+="  - $name ($src)\n"
    done
  fi
  dialog --title "Résumé" --yesno "$txt\nLancer l'installation ?" 24 70
}

save_selection() {
  local i pkg
  {
    for i in $(printf '%s\n' "${!SELECTED[@]}" | sort -n); do
      IFS='|' read -r _ _ _ pkg _ <<< "${APPS[$i]}"
      echo "app:$pkg"
    done
    (( DOTFILE_CHOICE >= 0 )) && echo "dotfiles:${DOTFILES[$DOTFILE_CHOICE]%%|*}"
  } > "$SELECTION_FILE"
}

load_selection() {
  [[ -f "$SELECTION_FILE" ]] || return 0
  dialog --title "Sélection sauvegardée" \
    --yesno "Une sélection a été trouvée :\n$SELECTION_FILE\n\nLa recharger ?" 10 70 || return 0
  local line kind value i pkg label
  while IFS= read -r line; do
    kind="${line%%:*}"; value="${line#*:}"
    case "$kind" in
      app)
        for i in "${!APPS[@]}"; do
          IFS='|' read -r _ _ _ pkg _ <<< "${APPS[$i]}"
          [[ "$pkg" == "$value" ]] && SELECTED[$i]=1
        done ;;
      dotfiles)
        for i in "${!DOTFILES[@]}"; do
          label="${DOTFILES[$i]%%|*}"
          [[ "$label" == "$value" ]] && DOTFILE_CHOICE=$i
        done ;;
    esac
  done < "$SELECTION_FILE"
}

main_menu() {
  local dot_label choice
  while true; do
    if (( DOTFILE_CHOICE >= 0 )); then
      dot_label="${DOTFILES[$DOTFILE_CHOICE]%%|*}"
    else
      dot_label="aucun"
    fi
    choice=$(dialog --title "Arch post-install" --menu "Que veux-tu installer ?" \
      16 70 5 \
      1 "Dotfiles : $dot_label" \
      2 "Programmes : $(count_selected) sélectionné(s)" \
      3 "Lancer l'installation" \
      4 "Sauvegarder la sélection" \
      5 "Quitter" 3>&1 1>&2 2>&3) || exit 0
    case "$choice" in
      1) menu_dotfiles ;;
      2) menu_programmes ;;
      3) if confirm_summary; then save_selection; return; fi ;;
      4) save_selection
         dialog --title "Sauvegarde" --msgbox "Sélection sauvegardée dans :\n$SELECTION_FILE" 8 70 ;;
      5) exit 0 ;;
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

load_selection
main_menu
run_install
