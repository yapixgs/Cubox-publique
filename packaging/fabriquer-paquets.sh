#!/usr/bin/env bash
#
# fabriquer-paquets.sh — construit les paquets « prêts à l'emploi » de Cubox.
#
# Chaque paquet embarque un JRE Java 21 : l'utilisateur final n'a **rien**
# à installer (pas besoin de Java sur la machine). C'est ce qu'on distribue
# uniquement pour les **versions finales** (à téléverser en *Release* sur la forge).
#
# À lancer sur une machine Linux (les deux paquets, Windows et Linux, sont
# assemblés depuis Linux — le lanceur Windows `Cubox.exe` cherche son Java
# dans le dossier `jre-x64\` placé à côté de lui).
#
# Usage :
#   ./packaging/fabriquer-paquets.sh            # version auto-détectée depuis le build
#   ./packaging/fabriquer-paquets.sh 1.0        # force le numéro de version
#
# Sorties (dans dist/) :
#   Cubox-<version>-windows-x64.zip     -> décompresser, lancer Installer.exe
#   Cubox-<version>-linux-x64.tar.gz    -> décompresser, lancer ./install.sh
#   Cubox-<version>-SHA256.txt          -> sommes de contrôle
#
# Depuis la 1.3, chaque archive contient un INSTALLEUR en plus du programme :
# l'utilisateur extrait, lance un fichier, et se retrouve avec Cubox installé
# proprement (raccourcis, entrée de menu, désinstalleur). Les binaires restent
# utilisables tels quels pour qui préfère le mode portable.
#
# `makensis` (paquet `nsis`) est nécessaire pour l'installeur Windows. S'il est
# absent, le .zip est produit SANS installeur — et le script le dit fort, parce
# qu'une archive silencieusement amputée est exactement le genre de régression
# qu'on ne découvre que chez l'utilisateur.
#
set -euo pipefail

# --- Réglages ---------------------------------------------------------------
# JRE embarqué, épinglé avec ses sommes de contrôle (R8.4, R9.5) : la même version donne
# les mêmes paquets. Même version que l'image de construction (packaging/Dockerfile).
readonly JRE_VERSION="21.0.12.1+1"
readonly JRE_FICHIER="${JRE_VERSION/+/_}"
readonly TEMURIN="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-${JRE_VERSION/+/%2B}"
readonly TEMURIN_WIN="$TEMURIN/OpenJDK21U-jre_x64_windows_hotspot_${JRE_FICHIER}.zip"
readonly TEMURIN_WIN_SHA256="d35f31e712f0fcf6ac5a093edc90204fbff22f720ba3950bd09d331d5e621636"
readonly TEMURIN_LINUX="$TEMURIN/OpenJDK21U-jre_x64_linux_hotspot_${JRE_FICHIER}.tar.gz"
readonly TEMURIN_LINUX_SHA256="2413149700df0f7d440500a84a8f764c535f21e5a5e87d38328b64eec2c5b500"

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly RACINE
readonly BIBLIOTHEQUES="HMCL/build/libs"
readonly CACHE_JRE="build/jre-cache"
readonly SORTIE="dist"

cd "$RACINE"

exiger() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Outil manquant : $1 (installe-le)"; exit 1; }; }
exiger curl; exiger unzip; exiger tar; exiger zip; exiger sha256sum

# --- 1/4 : compilation ------------------------------------------------------
# `clean` d'abord : un paquet de release doit toujours repartir d'un build neuf,
# sinon un build/ périmé peut embarquer une ancienne version (hmcl.properties).
echo "🔨 1/4  Compilation (gradlew clean :HMCL:makeExecutables)…"
./gradlew clean :HMCL:makeExecutables --no-daemon

# Détecte la version depuis le .exe produit (Cubox-<version>.exe)
executable="$(find "$BIBLIOTHEQUES" -maxdepth 1 -name 'Cubox-*.exe' 2>/dev/null | head -n1 || true)"
[ -n "$executable" ] || { echo "❌ Cubox-*.exe introuvable dans $BIBLIOTHEQUES — le build a-t-il réussi ?"; exit 1; }
detectee="$(basename "$executable" .exe)"          # Cubox-<version>
detectee="${detectee#Cubox-}"               # <version>
readonly VERSION="${1:-$detectee}"
readonly SCRIPT_SH="$BIBLIOTHEQUES/Cubox-${detectee}.sh"
[ -f "$SCRIPT_SH" ] || { echo "❌ Cubox-${detectee}.sh introuvable dans $BIBLIOTHEQUES"; exit 1; }
echo "   → version : $VERSION"

mkdir -p "$CACHE_JRE" "$SORTIE"

telecharger_jre() {  # $1=url  $2=fichier-cache  $3=sha256 attendu
  if [ ! -s "$2" ]; then
    echo "   ⬇️  $(basename "$2")…"
    curl -fSL --retry 3 -o "$2" "$1"
  else
    echo "   ♻️  $(basename "$2") (déjà en cache)"
  fi
  echo "$3  $2" | sha256sum -c - >/dev/null \
    || { echo "❌ Somme de contrôle invalide : $2"; rm -f "$2"; exit 1; }
}

# Extrait l'archive ($1) puis renomme son unique dossier racine en jre-x64 sous $2.
extraire_en_jre() {  # $1=archive  $2=dossier-destination-parent
  local temporaire; temporaire="$(mktemp -d)"
  case "$1" in
    *.zip)    unzip -q "$1" -d "$temporaire" ;;
    *.tar.gz) tar -xzf "$1" -C "$temporaire" ;;
  esac
  # L'archive Temurin contient un unique dossier racine (jdk-21...-jre).
  local interieur; interieur="$(find "$temporaire" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  [ -n "$interieur" ] || { echo "❌ Archive JRE inattendue : $1"; exit 1; }
  mv "$interieur" "$2/jre-x64"
  rm -rf "$temporaire"
}

echo "📦 2/4  Récupération des JRE Java ${JRE_VERSION}…"
readonly ZIP_WINDOWS="$CACHE_JRE/jre-${JRE_FICHIER}-win-x64.zip"
readonly TGZ_LINUX="$CACHE_JRE/jre-${JRE_FICHIER}-linux-x64.tar.gz"
telecharger_jre "$TEMURIN_WIN"   "$ZIP_WINDOWS" "$TEMURIN_WIN_SHA256"
telecharger_jre "$TEMURIN_LINUX" "$TGZ_LINUX" "$TEMURIN_LINUX_SHA256"

# --- 3/4 : paquet Windows ---------------------------------------------------
echo "🪟 3/4  Paquet Windows (Installer.exe + Cubox.exe + jre-x64\\)…"
dossier_windows="$SORTIE/Cubox-$VERSION-windows-x64"
rm -rf "$dossier_windows"; mkdir -p "$dossier_windows"
cp "$executable" "$dossier_windows/Cubox.exe"
extraire_en_jre "$ZIP_WINDOWS" "$dossier_windows"

if command -v makensis >/dev/null 2>&1; then
  echo "   🧰 Compilation de l'installeur (makensis)…"
  # On compile DEPUIS packaging/installer : NSIS résout `MUI_ICON "cubox.ico"`
  # par rapport au répertoire courant, pas au dossier du script. Lancé depuis
  # la racine, il ne trouverait pas l'icône.
  #
  # -DVERSION : le numéro apparaît dans le titre de la fenêtre et dans
  # « Applications et fonctionnalités ». Sans lui, NSIS retombe sur 0.0 et
  # l'entrée de désinstallation affiche une version mensongère.
  ( cd packaging/installer && makensis -V2 -DVERSION="$VERSION" cubox.nsi )
  mv packaging/installer/Installer.exe "$dossier_windows/Installer.exe"
  echo "   → Installer.exe ($(du -h "$dossier_windows/Installer.exe" | cut -f1))"
else
  echo "   ⚠️  makensis absent → le .zip Windows N'AURA PAS d'installeur."
  echo "   ⚠️  Installe le paquet « nsis » pour produire une archive complète."
fi

( cd "$SORTIE" && zip -qr "Cubox-$VERSION-windows-x64.zip" "Cubox-$VERSION-windows-x64" )

# --- 4/4 : paquet Linux -----------------------------------------------------
echo "🐧 4/4  Paquet Linux (install.sh + Cubox.sh + jre-x64/)…"
dossier_linux="$SORTIE/Cubox-$VERSION-linux-x64"
rm -rf "$dossier_linux"; mkdir -p "$dossier_linux"
cp "$SCRIPT_SH" "$dossier_linux/Cubox.sh"; chmod +x "$dossier_linux/Cubox.sh"
extraire_en_jre "$TGZ_LINUX" "$dossier_linux"

cp packaging/installer/install.sh packaging/installer/uninstall.sh "$dossier_linux/"
chmod +x "$dossier_linux/install.sh" "$dossier_linux/uninstall.sh"
cp HMCL/image/cubox.png "$dossier_linux/cubox.png"
# install.sh lit ce fichier pour afficher la version : sans lui il annonce
# « inconnue », ce qui rend le support impossible.
printf '%s\n' "$VERSION" > "$dossier_linux/VERSION"

( cd "$SORTIE" && tar -czf "Cubox-$VERSION-linux-x64.tar.gz" "Cubox-$VERSION-linux-x64" )

# --- Bonus : paquet Arch / pacman (si makepkg est dispo) --------------------
# Produit un .pkg.tar.zst installable avec « sudo pacman -U … » (Arch & dérivés).
# makepkg compile depuis la branche main du dépôt distant (source git du PKGBUILD),
# pense donc à pousser tes commits avant. Ignoré silencieusement hors Arch.
paquet_arch=""
if command -v makepkg >/dev/null 2>&1; then
  echo "📦 Bonus  Paquet Arch/pacman (makepkg)…"
  # -C (--cleanbuild) supprime le $srcdir avant le build : indispensable ici car
  # « git clean » du dépôt n'efface PAS packaging/aur/src/Cubox (dépôt git imbriqué),
  # et un build/ périmé y ferait réembarquer une ancienne version dans le jar.
  ( cd packaging/aur && rm -f ./*.pkg.tar.zst && makepkg -Cf --noconfirm )
  paquet="$(find packaging/aur -maxdepth 1 -name 'cubox-*.pkg.tar.zst' | head -n1 || true)"
  if [ -n "$paquet" ]; then
    cp "$paquet" "$SORTIE/"
    paquet_arch="$(basename "$paquet")"
    echo "   → $paquet_arch"
  else
    echo "   ⚠️  paquet pacman non produit (voir la sortie makepkg ci-dessus)"
  fi
else
  echo "ℹ️  makepkg absent → paquet Arch/pacman non généré (normal hors Arch Linux)."
fi

# --- Sommes de contrôle + ménage des dossiers intermédiaires ----------------
rm -rf "$dossier_windows" "$dossier_linux"
( cd "$SORTIE" && sha256sum \
    "Cubox-$VERSION-windows-x64.zip" \
    "Cubox-$VERSION-linux-x64.tar.gz" \
    ${paquet_arch:+"$paquet_arch"} \
    > "Cubox-$VERSION-SHA256.txt" )

echo
echo "✅ Terminé. Paquets dans $SORTIE/ :"
ls -lh "$SORTIE"/ 2>/dev/null
echo
echo "👉 Téléverse ces fichiers dans une *Release* sur la forge."
echo "   Windows     : décompresser le .zip → lancer Installer.exe"
echo "   Linux       : décompresser le .tar.gz → ./install.sh"
# ⚠️ `[ ... ] && echo ...` EN DERNIÈRE LIGNE renvoie 1 quand le test est faux.
# C'est le statut de sortie du script tout entier — donc un échec, alors que
# tout s'est bien passé. Invisible sur Arch (où `paquet_arch` est toujours
# renseigné), fatal partout ailleurs : c'est ce qui faisait échouer la CI
# après une construction parfaitement réussie.
if [ -n "$paquet_arch" ]; then
  echo "   Arch/pacman : sudo pacman -U $paquet_arch"
fi
