# Arch-post-install-setup
Un petit installateur en TUI pour Arch Linux : tu réinstalles ta machine, tu lances le script, tu coches ce que tu veux, et il s'occupe du reste.

## Ce que ça fait
Menu interactif dans le terminal (whiptail), flèches + espace + entrée
Dotfiles : choix d'un setup Hyprland (par défaut Satoxyan - expressive-pC)
Programmes triés par catégories : Navigateurs, Socials, Média, Jeux, Productivité
Gère tout seul les différentes sources : pacman, AUR (via yay) et flatpak
Résumé avant de lancer, et si une install plante il continue avec le reste
## Utilisation
```bash
sudo pacman -S git
```
```bash
git clone https://github.com/nath89-52/arch-setup.git
cd arch-setup
chmod +x arch-installer.sh
./arch-installer.sh
```

## ⚠️ À lancer en utilisateur normal, pas en root (sudo sera demandé quand il faut).

## Ajouter tes propres apps

Ouvre arch-installer.sh, tout en haut tu as deux listes à modifier.

Apps : une ligne par app, au format **Catégorie|Nom affiché|source|paquet**

```bash
"Navigateurs|Firefox|pacman|firefox"
"Socials|Vesktop|aur|vesktop-bin"
"Média|OBS Studio|flatpak|com.obsproject.Studio"
```
Dotfiles : Nom|URL git|dossier|commande à lancer

```bash
"Satoxyan - expressive-pC|https://github.com/Satoxyan/dots-hyprfork.git|dots-hyprfork|./setup install"
```
## Notes
Si tu coches Steam, le dépôt multilib est activé automatiquement
Les dotfiles sont installés en dernier, parce qu'ils écrasent souvent des configs
Fait pour Arch (ou dérivés avec pacman), ça ne marchera pas ailleurs
