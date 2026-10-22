#!/usr/bin/env bash
#
# Installe Cubox pour l'utilisateur courant.
#
#   tar -xzf Cubox-<version>-linux-x64.tar.gz
#   cd Cubox-<version>-linux-x64
#   ./install.sh
#
# Volontairement SANS sudo : tout va dans le home. Une install système
# imposerait une élévation à chaque mise à jour, pour un logiciel qui n'a
# besoin d'aucun privilège — et laisserait des fichiers root dans /opt que
# l'utilisateur ne pourrait plus nettoyer lui-même.
#
# Emplacements (conformes à la spécification XDG) :
#   ~/.local/share/cubox/app           les fichiers du programme
#   ~/.local/bin/cubox                 la commande
#   ~/.local/share/applications/…      l'entrée de menu
#   ~/.local/share/icons/hicolor/…     l'icône
#
# Les données de jeu (mondes, mods, configuration) vont dans
# ~/.local/share/cubox et ne sont JAMAIS touchées par ce script : réinstaller
# ou désinstaller ne détruit rien.
set -euo pipefail

SOURCE_ARCHIVE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DONNEES="${XDG_DATA_HOME:-$HOME/.local/share}"
DOSSIER_APPLI="$DONNEES/cubox/app"
DOSSIER_COMMANDES="$HOME/.local/bin"
DOSSIER_MENU="$DONNEES/applications"
DOSSIER_ICONES="$DONNEES/icons/hicolor/256x256/apps"

afficher_etape()  { printf '\033[36m==> %s\033[0m\n' "$*"; }
afficher_ok()     { printf '\033[32m  ✔ %s\033[0m\n' "$*"; }
afficher_alerte() { printf '\033[33m  ! %s\033[0m\n' "$*"; }
afficher_erreur() { printf '\033[31m  ✘ %s\033[0m\n' "$*" >&2; }

# --- Garde-fous -------------------------------------------------------------
# Une archive partiellement extraite produirait une installation cassée qui ne
# se manifesterait qu'au premier lancement. On refuse tout de suite.
for requis in Cubox.sh jre-x64/bin/java; do
  if [[ ! -e "$SOURCE_ARCHIVE/$requis" ]]; then
    afficher_erreur "Fichier manquant : $requis"
    afficher_erreur "Extrais l'archive ENTIÈRE, puis relance ./install.sh depuis le dossier extrait."
    exit 1
  fi
done

if [[ $EUID -eq 0 ]]; then
  afficher_erreur "Ne lance pas ce script en root : Cubox s'installe dans ton dossier personnel."
  afficher_erreur "Relance-le sans sudo."
  exit 1
fi

VERSION="inconnue"
[[ -f "$SOURCE_ARCHIVE/VERSION" ]] && VERSION="$(<"$SOURCE_ARCHIVE/VERSION")"

echo
echo "  Cubox $VERSION — installation pour $USER"
echo "  Destination : $DOSSIER_APPLI"
echo

# --- 1/4 : fichiers du programme -------------------------------------------
afficher_etape "1/4  Copie des fichiers"
# On remplace intégralement l'ancienne installation : un JRE mis à jour laisse
# sinon des bibliothèques orphelines de la version précédente, et Java charge
# parfois la mauvaise.
rm -rf "$DOSSIER_APPLI"
mkdir -p "$DOSSIER_APPLI"
cp -a "$SOURCE_ARCHIVE/Cubox.sh" "$SOURCE_ARCHIVE/jre-x64" "$DOSSIER_APPLI/"
chmod +x "$DOSSIER_APPLI/Cubox.sh" "$DOSSIER_APPLI/jre-x64/bin/java"
[[ -f "$SOURCE_ARCHIVE/VERSION" ]] && cp -a "$SOURCE_ARCHIVE/VERSION" "$DOSSIER_APPLI/"
afficher_ok "$(du -sh "$DOSSIER_APPLI" | cut -f1) installés"

# --- 2/4 : commande ---------------------------------------------------------
afficher_etape "2/4  Commande « cubox »"
mkdir -p "$DOSSIER_COMMANDES"
cat > "$DOSSIER_COMMANDES/cubox" <<EOF
#!/usr/bin/env bash
# Généré par l'installeur de Cubox — ne pas modifier à la main.
#
# On se place dans le dossier de données AVANT de lancer : Cubox range ses
# mondes et ses mods dans le répertoire courant. Sans ce cd, les données
# atterriraient là d'où la commande a été tapée, éparpillées un peu partout.
DONNEES_CUBOX="\${XDG_DATA_HOME:-\$HOME/.local/share}/cubox"
mkdir -p "\$DONNEES_CUBOX"
cd "\$DONNEES_CUBOX"
exec "$DOSSIER_APPLI/Cubox.sh" "\$@"
EOF
chmod +x "$DOSSIER_COMMANDES/cubox"
afficher_ok "$DOSSIER_COMMANDES/cubox"

case ":$PATH:" in
  *":$DOSSIER_COMMANDES:"*) ;;
  *) afficher_alerte "$DOSSIER_COMMANDES n'est pas dans ton PATH — la commande « cubox » ne sera pas trouvée."
     afficher_alerte "Ajoute ceci à ton ~/.bashrc ou ~/.zshrc :"
     afficher_alerte "    export PATH=\"\$HOME/.local/bin:\$PATH\""
     afficher_alerte "(l'entrée de menu, elle, fonctionnera de toute façon)" ;;
esac

# --- 3/4 : icône ------------------------------------------------------------
afficher_etape "3/4  Icône"
mkdir -p "$DOSSIER_ICONES"
if [[ -f "$SOURCE_ARCHIVE/cubox.png" ]]; then
  cp -a "$SOURCE_ARCHIVE/cubox.png" "$DOSSIER_ICONES/cubox.png"
  afficher_ok "$DOSSIER_ICONES/cubox.png"
else
  afficher_alerte "cubox.png absent de l'archive — entrée de menu sans icône"
fi

# --- 4/4 : entrée de menu ---------------------------------------------------
afficher_etape "4/4  Entrée de menu"
mkdir -p "$DOSSIER_MENU"
cat > "$DOSSIER_MENU/cubox.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Cubox
GenericName=Launcher Minecraft
Comment=Launcher Minecraft hors-ligne, mods et modpacks natifs
Exec=$DOSSIER_COMMANDES/cubox
Icon=cubox
Terminal=false
Categories=Game;
Keywords=minecraft;launcher;mods;modpack;
StartupWMClass=org.jackhuang.hmcl.Launcher
EOF
# Rafraîchir les caches est facultatif : sans ça l'entrée apparaît quand même,
# juste après la prochaine ouverture de session. On le fait si les outils sont
# là, et on n'échoue jamais pour si peu.
command -v update-desktop-database >/dev/null 2>&1 && \
  update-desktop-database "$DOSSIER_MENU" >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && \
  gtk-update-icon-cache -qtf "$DONNEES/icons/hicolor" >/dev/null 2>&1 || true
afficher_ok "$DOSSIER_MENU/cubox.desktop"

# --- Désinstalleur ----------------------------------------------------------
cp -a "$SOURCE_ARCHIVE/uninstall.sh" "$DOSSIER_APPLI/uninstall.sh" 2>/dev/null || true
chmod +x "$DOSSIER_APPLI/uninstall.sh" 2>/dev/null || true

echo
afficher_ok "Cubox $VERSION est installé."
echo
echo "  Lancer      : la commande « cubox », ou l'entrée « Cubox » de ton menu"
echo "  Désinstaller: $DOSSIER_APPLI/uninstall.sh"
echo "  Tes données : $DONNEES/cubox  (préservées lors des mises à jour)"
echo
echo "  Le dossier extrait ne sert plus à rien, tu peux le supprimer."
echo
