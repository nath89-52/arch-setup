# Arch-setup
Réinstaller Arch, c'est devoir réinstaller tous ses programmes un par un à chaque fois. Ce petit installateur en TUI règle ça : tu lances le script, tu coches ce que tu veux, et il s'occupe du reste.

## Ce que ça fait

- Interface dans le terminal (Textual) : catégories à gauche, détails de l'app à droite
- Dotfiles : choix d'un setup Hyprland (par défaut aucun)
- Programmes triés par catégories : Navigateurs, Fichiers, Socials, Média, Jeux, Productivité, Outils, Bureau, Développement...
- Barre de recherche : trouve une app par son nom, sa description ou sa catégorie (sans se soucier des accents ni des majuscules)
- Gère tout seul les différentes sources : pacman, AUR (via yay) et flatpak
- Résumé avant de lancer, et si une install plante il continue avec le reste
- Sauvegarde ta sélection et te propose de la recharger au prochain lancement (par chemin ou par lien)
- Installe tout seul ses dépendances (Python et Textual)

## Utilisation

### Sans cloner le dépôt

Une seule commande suffit pour lancer l'installateur directement depuis le terminal.

**Bash :**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/nath89-52/arch-setup/main/arch-setup.sh)
```

**Fish :**
```fish
bash (curl -fsSL https://raw.githubusercontent.com/nath89-52/arch-setup/main/arch-setup.sh | psub)
```

### Depuis le repo
Installer git
```bash
sudo pacman -S git
```
Copier le git et lancer le script
```bash
git clone https://github.com/nath89-52/arch-setup.git
cd arch-setup
chmod +x arch-setup.sh
./arch-setup.sh
```
## ⚠️ À lancer en utilisateur normal, pas en root (sudo sera demandé quand il faut).

## Les touches

| Touche | Action |
|---|---|
| ↑ ↓ | Naviguer |
| Espace / Entrée | Cocher une app, ou déplier une catégorie |
| `/` | Rechercher (Échap pour effacer) |
| `s` | Sauvegarder la sélection |
| `i` | Installer (une confirmation s'affiche avant) |
| `q` | Quitter sans rien installer |

## Les fichiers du projet

- `arch-setup.sh` : le script à lancer, il prépare les dépendances puis installe ta sélection
- `tui.py` : l'interface
- `apps.conf` : la liste des apps et des dotfiles

## Sauvegarder ta sélection

Appuie sur `s` dans l'interface pour enregistrer ta sélection dans un fichier `selection.conf` :
- à côté du script si tu l'as lancé depuis le repo
- dans ton dossier perso (`~/selection.conf`) si tu l'as lancé avec `curl`

Au prochain lancement, le script te demande où est ta sauvegarde : tu donnes un **chemin** ou un **lien**, et tout est déjà coché, tu n'as plus qu'à valider. Entrée pour passer cette étape.

Pour la retrouver après une réinstall, mets ton `selection.conf` dans ton repo GitHub et donne son lien « raw », par exemple :
```
https://raw.githubusercontent.com/<ton-user>/<ton-repo>/main/selection.conf
```

## Ajouter tes propres apps

Ouvre `apps.conf`, une ligne par entrée.

- Apps : au format **Catégorie|Nom affiché|source|paquet|Description**

Pour ajouter une nouvelle catégorie, il suffit d'écrire un nouveau nom : elle sera créée automatiquement.

La source peut être `pacman`, `aur` ou `flatpak`.

### Exemple
```
Navigateurs|Firefox|pacman|firefox|Navigateur web open source, rapide et respectueux de la vie privée
Socials|Vesktop (Discord + Vencord)|aur|vesktop-bin|Client Discord alternatif avec Vencord intégré (plugins, thèmes)
Media|OBS Studio|pacman|obs-studio|Enregistrement d'écran et streaming en direct
Media|GPU Screen Recorder|flatpak|com.dec05eba.gpu_screen_recorder|Enregistrement d'écran léger qui utilise le GPU
```
- Dotfiles : au format **@dotfiles|Nom|URL git|dossier|commande à lancer**

```
@dotfiles|Satoxyan - expressive-pC|https://github.com/Satoxyan/dots-hyprfork.git|dots-hyprfork|./setup install
```

## Notes
- Si tu coches Steam, le dépôt multilib est activé automatiquement
- Les dotfiles sont installés en dernier, parce qu'ils écrasent souvent des configs
- Fait pour Arch (ou dérivés avec pacman), ça ne marchera pas ailleurs
