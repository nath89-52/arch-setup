#!/usr/bin/env python3
"""Arch Setup : interface TUI (Textual) pour choisir ses apps et ses dotfiles.

Lancé par arch-setup.sh, qui lui passe ces variables d'environnement :
  APPS_CONF       fichier de la liste d'apps (apps.conf)
  SELECTION_FILE  où sauvegarder la sélection (touche s)
  PRELOAD_FILE    sélection à charger au démarrage (optionnel)
  RESULT_FILE     fichier écrit quand tu valides l'installation

Ce script n'installe rien : il écrit seulement ta sélection dans RESULT_FILE.
"""
import os
import unicodedata
from pathlib import Path

from rich.text import Text
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical, VerticalScroll
from textual.screen import ModalScreen
from textual.widgets import Footer, Header, Input, Static, Tree

SRC_STYLE = {"pacman": "cyan", "aur": "magenta", "flatpak": "yellow", "appimage": "bright_red"}


def norm(s: str) -> str:
    """Minuscules sans accents, pour que 'video' trouve 'vidéo'."""
    s = unicodedata.normalize("NFKD", s.lower())
    return "".join(c for c in s if not unicodedata.combining(c))


def parse_conf(path):
    apps, dotfiles = [], []
    for raw in Path(path).read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = [p.strip() for p in line.split("|")]
        if parts[0] == "@dotfiles":
            if len(parts) >= 5:
                dotfiles.append({"name": parts[1], "url": parts[2],
                                 "dir": parts[3], "cmd": "|".join(parts[4:])})
            continue
        if len(parts) < 4:
            continue
        apps.append({"cat": parts[0], "name": parts[1], "src": parts[2],
                     "pkg": parts[3], "desc": "|".join(parts[4:])})
    return apps, dotfiles


class ItemTree(Tree):
    """Arbre où espace / entrée coche une app (ou déplie une catégorie)."""

    BINDINGS = [
        Binding("space", "toggle_item", "Cocher"),
        Binding("enter", "toggle_item", "Cocher", show=False),
    ]

    def action_toggle_item(self) -> None:
        node = self.cursor_node
        if node is None or node.data is None:
            return
        if node.data[0] == "cat":
            node.toggle()
        else:
            self.app.toggle(node.data)


class ConfirmScreen(ModalScreen[bool]):
    BINDINGS = [
        Binding("y,enter", "confirm", "Installer"),
        Binding("n,escape", "cancel", "Annuler"),
    ]

    def __init__(self, summary: Text) -> None:
        super().__init__()
        self.summary = summary

    def compose(self) -> ComposeResult:
        with Vertical(id="dialog"):
            yield Static(Text("Lancer l'installation ?", style="bold"), id="confirm-title")
            with VerticalScroll(id="confirm-body"):
                yield Static(self.summary)
            yield Static(Text("Entrée / y : installer     Échap / n : annuler", style="dim"),
                         id="confirm-help")

    def action_confirm(self) -> None:
        self.dismiss(True)

    def action_cancel(self) -> None:
        self.dismiss(False)


class ArchSetup(App):
    TITLE = "Arch Setup"
    SUB_TITLE = "Choisis ce que tu veux installer"

    CSS = """
    #search { display: none; margin: 0 1; }
    #search.visible { display: block; }
    #main { height: 1fr; }
    #tree { width: 55%; border: round $primary; padding: 0 1; }
    #side { width: 45%; border: round $secondary; padding: 1 2; }
    #summary { margin-top: 1; padding-top: 1; border-top: solid $panel-lighten-2; }
    ConfirmScreen { align: center middle; }
    #dialog { width: 72; max-height: 80%; height: auto;
              border: round $accent; background: $panel; padding: 1 2; }
    #confirm-body { height: auto; max-height: 20; margin: 1 0; }
    """

    BINDINGS = [
        Binding("slash", "search", "Rechercher"),
        Binding("i", "install", "Installer"),
        Binding("s", "save", "Sauvegarder"),
        Binding("escape", "clear_search", "Effacer la recherche", show=False),
        Binding("q", "quit_app", "Quitter"),
    ]

    def __init__(self) -> None:
        super().__init__()
        conf = os.environ.get("APPS_CONF") or str(Path(__file__).with_name("apps.conf"))
        self.apps, self.dotfiles = parse_conf(conf)
        self.selected: set[str] = set()
        self.dotfile: str | None = None
        self.query_text = ""
        self.leaf_nodes: dict = {}
        self.cat_nodes: dict = {}
        self.selection_file = os.environ.get("SELECTION_FILE") or str(Path.home() / "selection.conf")
        self.result_file = os.environ.get("RESULT_FILE") or "result.conf"
        self.preloaded = self.preload(os.environ.get("PRELOAD_FILE"))

    # ---------- état ----------

    def preload(self, path) -> int:
        """Charge une sélection sauvegardée (jamais exécutée : on compare juste des noms)."""
        if not path or not Path(path).is_file():
            return 0
        known = {a["pkg"] for a in self.apps}
        dots = {d["name"] for d in self.dotfiles}
        count = 0
        for raw in Path(path).read_text(encoding="utf-8", errors="replace").splitlines():
            kind, _, value = raw.strip().partition(":")
            if kind == "app" and value in known:
                self.selected.add(value)
                count += 1
            elif kind == "dotfiles" and value in dots:
                self.dotfile = value
        return count

    def write_selection(self, path) -> None:
        lines = [f"app:{a['pkg']}" for a in self.apps if a["pkg"] in self.selected]
        if self.dotfile:
            lines.append(f"dotfiles:{self.dotfile}")
        Path(path).write_text("\n".join(lines) + "\n", encoding="utf-8")

    def is_on(self, key) -> bool:
        kind, value = key
        return value in self.selected if kind == "app" else self.dotfile == value

    def toggle(self, data) -> None:
        kind, value = data
        if kind == "app":
            self.selected ^= {value}
        else:
            self.dotfile = None if self.dotfile == value else value
        self.refresh_labels()
        node = self.leaf_nodes.get(data)
        if node is not None:
            self.show_info(node)

    # ---------- interface ----------

    def compose(self) -> ComposeResult:
        yield Header()
        yield Input(placeholder="Rechercher (nom, description, catégorie)…", id="search")
        with Horizontal(id="main"):
            yield ItemTree("Arch Setup", id="tree")
            with VerticalScroll(id="side"):
                yield Static(id="info")
                yield Static(id="summary")
        yield Footer()

    def on_mount(self) -> None:
        tree = self.query_one("#tree", ItemTree)
        tree.show_root = False
        tree.border_title = "Catégories"
        self.query_one("#side").border_title = "Détails"
        self.rebuild()
        tree.focus()
        if self.preloaded:
            self.notify(f"{self.preloaded} app(s) chargée(s) depuis ta sauvegarde.")

    def leaf_label(self, kind: str, value: str) -> Text:
        on = self.is_on((kind, value))
        t = Text()
        t.append("[✔] " if on else "[ ] ", style="bold green" if on else "dim")
        if kind == "app":
            a = next(x for x in self.apps if x["pkg"] == value)
            t.append(a["name"], style="bold" if on else "")
            t.append("  " + a["src"], style=SRC_STYLE.get(a["src"], "white") + " dim")
        else:
            t.append(value, style="bold" if on else "")
        return t

    def cat_label(self, cat: str, keys: list) -> Text:
        n_on = sum(1 for k in keys if self.is_on(k))
        t = Text(cat, style="bold")
        t.append(f"  ({n_on}/{len(keys)})", style="green" if n_on else "dim")
        return t

    def rebuild(self) -> None:
        tree = self.query_one("#tree", ItemTree)
        tree.clear()
        self.leaf_nodes.clear()
        self.cat_nodes.clear()
        q = norm(self.query_text.strip())
        searching = bool(q)

        dots = [d for d in self.dotfiles if not searching or q in norm(d["name"] + " dotfiles")]
        if dots:
            node = tree.root.add("Dotfiles", data=("cat", "Dotfiles"), expand=searching)
            keys = []
            for d in dots:
                key = ("dot", d["name"])
                self.leaf_nodes[key] = node.add_leaf("", data=key)
                keys.append(key)
            self.cat_nodes["Dotfiles"] = (node, keys)

        cats: dict[str, list] = {}
        for a in self.apps:
            hay = norm(" ".join([a["name"], a["pkg"], a["desc"], a["cat"]]))
            if not searching or q in hay:
                cats.setdefault(a["cat"], []).append(a)
        for cat, items in cats.items():
            node = tree.root.add(cat, data=("cat", cat), expand=searching)
            keys = []
            for a in items:
                key = ("app", a["pkg"])
                self.leaf_nodes[key] = node.add_leaf("", data=key)
                keys.append(key)
            self.cat_nodes[cat] = (node, keys)

        tree.root.expand()
        self.refresh_labels()
        self.call_after_refresh(lambda: self.show_info(tree.cursor_node))

    def refresh_labels(self) -> None:
        for key, node in self.leaf_nodes.items():
            node.set_label(self.leaf_label(*key))
        for cat, (node, keys) in self.cat_nodes.items():
            node.set_label(self.cat_label(cat, keys))
        self.update_summary()

    def update_summary(self) -> None:
        t = Text()
        t.append("Sélection\n", style="bold")
        t.append(f"{len(self.selected)} app(s)", style="green" if self.selected else "dim")
        t.append("   Dotfiles : ")
        t.append(self.dotfile or "aucun", style="green" if self.dotfile else "dim")
        self.query_one("#summary", Static).update(t)

    def show_info(self, node) -> None:
        info = self.query_one("#info", Static)
        t = Text()
        data = node.data if node is not None else None
        if data is None:
            if self.query_text.strip():
                t.append("Aucun résultat.", style="dim")
            else:
                t.append("Utilise ↑ ↓ pour naviguer, Espace pour cocher.\n", style="dim")
                t.append("/ pour rechercher, i pour installer, s pour sauvegarder.", style="dim")
        elif data[0] == "cat":
            keys = self.cat_nodes.get(data[1], (None, []))[1]
            t.append(data[1] + "\n", style="bold")
            t.append(f"{len(keys)} entrée(s) dans cette catégorie.\n", style="dim")
            t.append("Entrée ou Espace pour déplier / replier.")
        elif data[0] == "app":
            a = next(x for x in self.apps if x["pkg"] == data[1])
            t.append(a["name"] + "\n\n", style="bold")
            t.append("Source : ", style="dim")
            t.append(a["src"] + "\n", style=SRC_STYLE.get(a["src"], "white"))
            t.append("Paquet : ", style="dim")
            t.append(a["pkg"] + "\n\n")
            t.append(a["desc"] or "Pas de description.")
        else:
            d = next(x for x in self.dotfiles if x["name"] == data[1])
            t.append(d["name"] + "\n\n", style="bold")
            t.append("Dépôt : ", style="dim")
            t.append(d["url"] + "\n")
            t.append("Commande : ", style="dim")
            t.append(d["cmd"] + "\n\n")
            t.append("Un seul choix possible. Installé en dernier.", style="dim")
        info.update(t)

    def on_tree_node_highlighted(self, event) -> None:
        self.show_info(event.node)

    # ---------- recherche ----------

    def action_search(self) -> None:
        box = self.query_one("#search", Input)
        box.add_class("visible")
        box.focus()

    def on_input_changed(self, event: Input.Changed) -> None:
        self.query_text = event.value
        self.rebuild()

    def on_input_submitted(self, event: Input.Submitted) -> None:
        self.query_one("#tree", ItemTree).focus()

    def action_clear_search(self) -> None:
        box = self.query_one("#search", Input)
        if box.has_class("visible") or self.query_text:
            box.value = ""
            box.remove_class("visible")
            self.query_text = ""
            self.rebuild()
        self.query_one("#tree", ItemTree).focus()

    # ---------- actions ----------

    def summary_text(self) -> Text:
        t = Text()
        t.append("Dotfiles : ", style="bold")
        t.append((self.dotfile or "aucun") + "\n\n")
        groups: dict[str, list] = {}
        for a in self.apps:
            if a["pkg"] in self.selected:
                groups.setdefault(a["src"], []).append(a["name"])
        t.append(f"Programmes ({len(self.selected)}) :\n", style="bold")
        if not groups:
            t.append("  aucun\n")
        for src, names in groups.items():
            t.append(f"  {src}", style=SRC_STYLE.get(src, "white"))
            t.append(" : " + ", ".join(names) + "\n")
        return t

    def action_install(self) -> None:
        if not self.selected and self.dotfile is None:
            self.notify("Rien n'est sélectionné.", severity="warning")
            return

        def done(ok: bool | None) -> None:
            if ok:
                self.write_selection(self.result_file)
                self.exit()

        self.push_screen(ConfirmScreen(self.summary_text()), done)

    def action_save(self) -> None:
        try:
            self.write_selection(self.selection_file)
            self.notify(f"Sélection sauvegardée :\n{self.selection_file}")
        except OSError as e:
            self.notify(f"Sauvegarde impossible : {e}", severity="error")

    def action_quit_app(self) -> None:
        self.exit()


if __name__ == "__main__":
    ArchSetup().run()
