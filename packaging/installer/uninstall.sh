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

DONNEES="${XDG_DATA_HOME:-$HOME/.local/share}"
DOSSIER_CUBOX="$DONNEES/cubox"
DOSSIER_APPLI="$DOSSIER_CUBOX/app"
COMMANDE="$HOME/.local/bin/cubox"
ENTREE_MENU="$DONNEES/applications/cubox.desktop"
ICONE="$DONNEES/icons/hicolor/256x256/apps/cubox.png"

TOUT_EFFACER=0
[[ "${1:-}" == "--purge" ]] && TOUT_EFFACER=1

afficher_ok()     { printf '\033[32m  ✔ %s\033[0m\n' "$*"; }
afficher_alerte() { printf '\033[33m  ! %s\033[0m\n' "$*"; }

echo
echo "  Désinstallation de Cubox"
echo

for cible in "$COMMANDE" "$ENTREE_MENU" "$ICONE"; do
  if [[ -e "$cible" ]]; then rm -f "$cible"; afficher_ok "supprimé : $cible"; fi
done

if [[ -d "$DOSSIER_APPLI" ]]; then
  # `rm -rf` sur un chemin construit à partir de variables mérite une
  # vérification : si DONNEES était vide, on effacerait /cubox/app.
  [[ "$DOSSIER_APPLI" == "$HOME"/* || "$DOSSIER_APPLI" == "${XDG_DATA_HOME:-/dev/null}"/* ]] \
    || { echo "chemin inattendu, abandon : $DOSSIER_APPLI" >&2; exit 1; }
  rm -rf "$DOSSIER_APPLI"
  afficher_ok "supprimé : $DOSSIER_APPLI"
fi

command -v update-desktop-database >/dev/null 2>&1 && \
  update-desktop-database "$DONNEES/applications" >/dev/null 2>&1 || true

if (( TOUT_EFFACER )); then
  if [[ -d "$DOSSIER_CUBOX" ]]; then
    echo
    afficher_alerte "--purge : suppression définitive de $DOSSIER_CUBOX"
    afficher_alerte "Cela efface tes mondes, tes mods et ta configuration."
    read -r -p "  Taper « supprimer » pour confirmer : " reponse
    if [[ "$reponse" == "supprimer" ]]; then
      rm -rf "$DOSSIER_CUBOX"
      afficher_ok "supprimé : $DOSSIER_CUBOX"
    else
      afficher_alerte "annulé — les données sont conservées"
    fi
  fi
else
  echo
  echo "  Tes données sont conservées dans : $DOSSIER_CUBOX"
  # Surtout pas « $0 --purge » : ce script vient de s'auto-supprimer avec
  # $DOSSIER_APPLI. On donne la commande qui marchera encore dans cinq minutes.
  echo "  Pour tout effacer :  rm -rf \"$DOSSIER_CUBOX\""
fi
echo
