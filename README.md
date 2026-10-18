# Arch-setup
Un petit installateur en TUI pour Arch Linux : tu réinstalles ta machine, tu lances le script, tu coches ce que tu veux, et il s'occupe du reste.

## Ce que ça fait

- Menu interactif dans le terminal (dialog), flèches + espace + entrée
- Dotfiles : choix d'un setup Hyprland (par défaut none)
- Programmes triés par catégories : Navigateurs, Socials, Média, Jeux, Productivité...
- Barre de recherche : trouve une app par son nom, sa description ou sa catégorie (sans se soucier des accents ni des majuscules)
- Gère tout seul les différentes sources : pacman, AUR (via yay) et flatpak
- Résumé avant de lancer, et si une install plante il continue avec le reste
- Sauvegarde ta sélection dans `selection.conf` et te propose de la recharger au prochain lancement (doit etre dans le meme dossier)

## Utilisation
Installer git
```bash
sudo pacman -S git
```
Copier le git et lancer le script
```bash
git clone https://github.com/nath89-52/arch-setup.git
cd arch-setup
chmod +x arch-installer.sh
./arch-installer.sh
```
## ⚠️ À lancer en utilisateur normal, pas en root (sudo sera demandé quand il faut).

## Sauvegarder ta sélection

Ta sélection est enregistrée dans un fichier `selection.conf`, à côté du script :
- automatiquement quand tu lances l'installation
- ou à la main avec **"Sauvegarder la sélection"** dans le menu principal

Au prochain lancement, le script te propose de la recharger : tout est déjà coché, tu n'as plus qu'à valider.

## Ajouter tes propres apps

Ouvre arch-installer.sh, tout en haut tu as deux listes à modifier.

- Apps : une ligne par app, au format **Catégorie|Nom affiché|source|paquet|Description**

Pour ajouté une nouvelle catégorie il suffi de change son nom, elle sera crée automatiquement.

### Exemple
```bash
"Navigateurs|Firefox|pacman|firefox|Navigateur web open source, rapide et respectueux de la vie privée"
"Socials|Vesktop (Discord + Vencord)|aur|vesktop-bin|Client Discord alternatif avec Vencord intégré (plugins, thèmes)"
"Media|OBS Studio|pacman|obs-studio|Enregistrement d'écran et streaming en direct"
```
- Dotfiles : Nom|URL git|dossier|commande à lancer

```bash
"Satoxyan - expressive-pC|https://github.com/Satoxyan/dots-hyprfork.git|dots-hyprfork|./setup install"
```
## Notes
Si tu coches Steam, le dépôt multilib est activé automatiquement
Les dotfiles sont installés en dernier, parce qu'ils écrasent souvent des configs
Fait pour Arch (ou dérivés avec pacman), ça ne marchera pas ailleurs
