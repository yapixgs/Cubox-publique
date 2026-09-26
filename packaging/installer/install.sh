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

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
APP_DIR="$DATA_HOME/cubox/app"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$DATA_HOME/applications"
ICON_DIR="$DATA_HOME/icons/hicolor/256x256/apps"

c_info() { printf '\033[36m==> %s\033[0m\n' "$*"; }
c_ok()   { printf '\033[32m  ✔ %s\033[0m\n' "$*"; }
c_warn() { printf '\033[33m  ! %s\033[0m\n' "$*"; }
c_err()  { printf '\033[31m  ✘ %s\033[0m\n' "$*" >&2; }

# --- Garde-fous -------------------------------------------------------------
# Une archive partiellement extraite produirait une installation cassée qui ne
# se manifesterait qu'au premier lancement. On refuse tout de suite.
for requis in Cubox.sh jre-x64/bin/java; do
  if [[ ! -e "$SOURCE/$requis" ]]; then
    c_err "Fichier manquant : $requis"
    c_err "Extrais l'archive ENTIÈRE, puis relance ./install.sh depuis le dossier extrait."
    exit 1
  fi
done

if [[ $EUID -eq 0 ]]; then
  c_err "Ne lance pas ce script en root : Cubox s'installe dans ton dossier personnel."
  c_err "Relance-le sans sudo."
  exit 1
fi

VERSION="inconnue"
[[ -f "$SOURCE/VERSION" ]] && VERSION="$(<"$SOURCE/VERSION")"

echo
echo "  Cubox $VERSION — installation pour $USER"
echo "  Destination : $APP_DIR"
echo

# --- 1/4 : fichiers du programme -------------------------------------------
c_info "1/4  Copie des fichiers"
# On remplace intégralement l'ancienne installation : un JRE mis à jour laisse
# sinon des bibliothèques orphelines de la version précédente, et Java charge
# parfois la mauvaise.
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
cp -a "$SOURCE/Cubox.sh" "$SOURCE/jre-x64" "$APP_DIR/"
chmod +x "$APP_DIR/Cubox.sh" "$APP_DIR/jre-x64/bin/java"
[[ -f "$SOURCE/VERSION" ]] && cp -a "$SOURCE/VERSION" "$APP_DIR/"
c_ok "$(du -sh "$APP_DIR" | cut -f1) installés"

# --- 2/4 : commande ---------------------------------------------------------
c_info "2/4  Commande « cubox »"
mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/cubox" <<EOF
#!/usr/bin/env bash
# Généré par l'installeur de Cubox — ne pas modifier à la main.
#
# On se place dans le dossier de données AVANT de lancer : Cubox range ses
# mondes et ses mods dans le répertoire courant. Sans ce cd, les données
# atterriraient là d'où la commande a été tapée, éparpillées un peu partout.
CUBOX_DATA="\${XDG_DATA_HOME:-\$HOME/.local/share}/cubox"
mkdir -p "\$CUBOX_DATA"
cd "\$CUBOX_DATA"
exec "$APP_DIR/Cubox.sh" "\$@"
EOF
chmod +x "$BIN_DIR/cubox"
c_ok "$BIN_DIR/cubox"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) c_warn "$BIN_DIR n'est pas dans ton PATH — la commande « cubox » ne sera pas trouvée."
     c_warn "Ajoute ceci à ton ~/.bashrc ou ~/.zshrc :"
     c_warn "    export PATH=\"\$HOME/.local/bin:\$PATH\""
     c_warn "(l'entrée de menu, elle, fonctionnera de toute façon)" ;;
esac

# --- 3/4 : icône ------------------------------------------------------------
c_info "3/4  Icône"
mkdir -p "$ICON_DIR"
if [[ -f "$SOURCE/cubox.png" ]]; then
  cp -a "$SOURCE/cubox.png" "$ICON_DIR/cubox.png"
  c_ok "$ICON_DIR/cubox.png"
else
  c_warn "cubox.png absent de l'archive — entrée de menu sans icône"
fi

# --- 4/4 : entrée de menu ---------------------------------------------------
c_info "4/4  Entrée de menu"
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_DIR/cubox.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Cubox
GenericName=Launcher Minecraft
Comment=Launcher Minecraft hors-ligne, mods et modpacks natifs
Exec=$BIN_DIR/cubox
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
  update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && \
  gtk-update-icon-cache -qtf "$DATA_HOME/icons/hicolor" >/dev/null 2>&1 || true
c_ok "$DESKTOP_DIR/cubox.desktop"

# --- Désinstalleur ----------------------------------------------------------
cp -a "$SOURCE/uninstall.sh" "$APP_DIR/uninstall.sh" 2>/dev/null || true
chmod +x "$APP_DIR/uninstall.sh" 2>/dev/null || true

echo
c_ok "Cubox $VERSION est installé."
echo
echo "  Lancer      : la commande « cubox », ou l'entrée « Cubox » de ton menu"
echo "  Désinstaller: $APP_DIR/uninstall.sh"
echo "  Tes données : $DATA_HOME/cubox  (préservées lors des mises à jour)"
echo
echo "  Le dossier extrait ne sert plus à rien, tu peux le supprimer."
echo
