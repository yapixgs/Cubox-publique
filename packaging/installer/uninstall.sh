#!/usr/bin/env bash
#
# Désinstalle Cubox pour l'utilisateur courant.
#
# Retire le programme, la commande, l'entrée de menu et l'icône.
# Les DONNÉES DE JEU sont conservées par défaut (mondes, mods, comptes,
# configuration) : une désinstallation qui efface les sauvegardes sans
# prévenir est une perte de données, pas un nettoyage.
#
#   ~/.local/share/cubox/uninstall.sh              retire le programme
#   ~/.local/share/cubox/uninstall.sh --purge      retire AUSSI les données
set -euo pipefail

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
CUBOX_HOME="$DATA_HOME/cubox"
APP_DIR="$CUBOX_HOME/app"
BIN="$HOME/.local/bin/cubox"
DESKTOP="$DATA_HOME/applications/cubox.desktop"
ICON="$DATA_HOME/icons/hicolor/256x256/apps/cubox.png"

PURGE=0
[[ "${1:-}" == "--purge" ]] && PURGE=1

c_ok()   { printf '\033[32m  ✔ %s\033[0m\n' "$*"; }
c_warn() { printf '\033[33m  ! %s\033[0m\n' "$*"; }

echo
echo "  Désinstallation de Cubox"
echo

for cible in "$BIN" "$DESKTOP" "$ICON"; do
  if [[ -e "$cible" ]]; then rm -f "$cible"; c_ok "supprimé : $cible"; fi
done

if [[ -d "$APP_DIR" ]]; then
  # `rm -rf` sur un chemin construit à partir de variables mérite une
  # vérification : si DATA_HOME était vide, on effacerait /cubox/app.
  [[ "$APP_DIR" == "$HOME"/* || "$APP_DIR" == "${XDG_DATA_HOME:-/dev/null}"/* ]] \
    || { echo "chemin inattendu, abandon : $APP_DIR" >&2; exit 1; }
  rm -rf "$APP_DIR"
  c_ok "supprimé : $APP_DIR"
fi

command -v update-desktop-database >/dev/null 2>&1 && \
  update-desktop-database "$DATA_HOME/applications" >/dev/null 2>&1 || true

if (( PURGE )); then
  if [[ -d "$CUBOX_HOME" ]]; then
    echo
    c_warn "--purge : suppression définitive de $CUBOX_HOME"
    c_warn "Cela efface tes mondes, tes mods et ta configuration."
    read -r -p "  Taper « supprimer » pour confirmer : " reponse
    if [[ "$reponse" == "supprimer" ]]; then
      rm -rf "$CUBOX_HOME"
      c_ok "supprimé : $CUBOX_HOME"
    else
      c_warn "annulé — les données sont conservées"
    fi
  fi
else
  echo
  echo "  Tes données sont conservées dans : $CUBOX_HOME"
  # Surtout pas « $0 --purge » : ce script vient de s'auto-supprimer avec
  # $APP_DIR. On donne la commande qui marchera encore dans cinq minutes.
  echo "  Pour tout effacer :  rm -rf \"$CUBOX_HOME\""
fi
echo
