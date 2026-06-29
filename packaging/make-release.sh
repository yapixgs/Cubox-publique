#!/usr/bin/env bash
#
# make-release.sh — construit les paquets « prêts à l'emploi » de Cubox.
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
#   ./packaging/make-release.sh            # version auto-détectée depuis le build
#   ./packaging/make-release.sh 1.0        # force le numéro de version
#
# Sorties (dans dist/) :
#   Cubox-<version>-windows-x64.zip     -> décompresser, double-clic sur Cubox.exe
#   Cubox-<version>-linux-x64.tar.gz    -> décompresser, lancer ./Cubox.sh
#   Cubox-<version>-SHA256.txt          -> sommes de contrôle
#
set -euo pipefail

# --- Réglages ---------------------------------------------------------------
readonly JRE_FEATURE=21
readonly TEMURIN_WIN="https://api.adoptium.net/v3/binary/latest/${JRE_FEATURE}/ga/windows/x64/jre/hotspot/normal/eclipse?project=jdk"
readonly TEMURIN_LINUX="https://api.adoptium.net/v3/binary/latest/${JRE_FEATURE}/ga/linux/x64/jre/hotspot/normal/eclipse?project=jdk"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT
readonly LIBS="HMCL/build/libs"
readonly CACHE="build/jre-cache"
readonly DIST="dist"

cd "$ROOT"

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Outil manquant : $1 (installe-le)"; exit 1; }; }
need curl; need unzip; need tar; need zip; need sha256sum

# --- 1/4 : compilation ------------------------------------------------------
# `clean` d'abord : un paquet de release doit toujours repartir d'un build neuf,
# sinon un build/ périmé peut embarquer une ancienne version (hmcl.properties).
echo "🔨 1/4  Compilation (gradlew clean :HMCL:makeExecutables)…"
./gradlew clean :HMCL:makeExecutables --no-daemon

# Détecte la version depuis le .exe produit (Cubox-<version>.exe)
exe="$(find "$LIBS" -maxdepth 1 -name 'Cubox-*.exe' 2>/dev/null | head -n1 || true)"
[ -n "$exe" ] || { echo "❌ Cubox-*.exe introuvable dans $LIBS — le build a-t-il réussi ?"; exit 1; }
detected="$(basename "$exe" .exe)"          # Cubox-<version>
detected="${detected#Cubox-}"               # <version>
readonly VERSION="${1:-$detected}"
readonly SH="$LIBS/Cubox-${detected}.sh"
[ -f "$SH" ] || { echo "❌ Cubox-${detected}.sh introuvable dans $LIBS"; exit 1; }
echo "   → version : $VERSION"

mkdir -p "$CACHE" "$DIST"

fetch_jre() {  # $1=url  $2=fichier-cache
  if [ ! -s "$2" ]; then
    echo "   ⬇️  $(basename "$2")…"
    curl -fSL --retry 3 -o "$2" "$1"
  else
    echo "   ♻️  $(basename "$2") (déjà en cache)"
  fi
}

# Extrait l'archive ($1) puis renomme son unique dossier racine en jre-x64 sous $2.
extract_as_jre() {  # $1=archive  $2=dossier-destination-parent
  local tmp; tmp="$(mktemp -d)"
  case "$1" in
    *.zip)    unzip -q "$1" -d "$tmp" ;;
    *.tar.gz) tar -xzf "$1" -C "$tmp" ;;
  esac
  # L'archive Temurin contient un unique dossier racine (jdk-21...-jre).
  local inner; inner="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -n1)"
  [ -n "$inner" ] || { echo "❌ Archive JRE inattendue : $1"; exit 1; }
  mv "$inner" "$2/jre-x64"
  rm -rf "$tmp"
}

echo "📦 2/4  Récupération des JRE Java ${JRE_FEATURE}…"
readonly WIN_ZIP="$CACHE/jre-${JRE_FEATURE}-win-x64.zip"
readonly LIN_TGZ="$CACHE/jre-${JRE_FEATURE}-linux-x64.tar.gz"
fetch_jre "$TEMURIN_WIN"   "$WIN_ZIP"
fetch_jre "$TEMURIN_LINUX" "$LIN_TGZ"

# --- 3/4 : paquet Windows ---------------------------------------------------
echo "🪟 3/4  Paquet Windows (Cubox.exe + jre-x64\\)…"
windir="$DIST/Cubox-$VERSION-windows-x64"
rm -rf "$windir"; mkdir -p "$windir"
cp "$exe" "$windir/Cubox.exe"
extract_as_jre "$WIN_ZIP" "$windir"
( cd "$DIST" && zip -qr "Cubox-$VERSION-windows-x64.zip" "Cubox-$VERSION-windows-x64" )

# --- 4/4 : paquet Linux -----------------------------------------------------
echo "🐧 4/4  Paquet Linux (Cubox.sh + jre-x64/)…"
lindir="$DIST/Cubox-$VERSION-linux-x64"
rm -rf "$lindir"; mkdir -p "$lindir"
cp "$SH" "$lindir/Cubox.sh"; chmod +x "$lindir/Cubox.sh"
extract_as_jre "$LIN_TGZ" "$lindir"
( cd "$DIST" && tar -czf "Cubox-$VERSION-linux-x64.tar.gz" "Cubox-$VERSION-linux-x64" )

# --- Bonus : paquet Arch / pacman (si makepkg est dispo) --------------------
# Produit un .pkg.tar.zst installable avec « sudo pacman -U … » (Arch & dérivés).
# makepkg compile depuis la branche main du dépôt distant (source git du PKGBUILD),
# pense donc à pousser tes commits avant. Ignoré silencieusement hors Arch.
pkg_built=""
if command -v makepkg >/dev/null 2>&1; then
  echo "📦 Bonus  Paquet Arch/pacman (makepkg)…"
  # -C (--cleanbuild) supprime le $srcdir avant le build : indispensable ici car
  # « git clean » du dépôt n'efface PAS packaging/aur/src/Cubox (dépôt git imbriqué),
  # et un build/ périmé y ferait réembarquer une ancienne version dans le jar.
  ( cd packaging/aur && rm -f ./*.pkg.tar.zst && makepkg -Cf --noconfirm )
  pkg="$(find packaging/aur -maxdepth 1 -name 'cubox-*.pkg.tar.zst' | head -n1 || true)"
  if [ -n "$pkg" ]; then
    cp "$pkg" "$DIST/"
    pkg_built="$(basename "$pkg")"
    echo "   → $pkg_built"
  else
    echo "   ⚠️  paquet pacman non produit (voir la sortie makepkg ci-dessus)"
  fi
else
  echo "ℹ️  makepkg absent → paquet Arch/pacman non généré (normal hors Arch Linux)."
fi

# --- Sommes de contrôle + ménage des dossiers intermédiaires ----------------
rm -rf "$windir" "$lindir"
( cd "$DIST" && sha256sum \
    "Cubox-$VERSION-windows-x64.zip" \
    "Cubox-$VERSION-linux-x64.tar.gz" \
    ${pkg_built:+"$pkg_built"} \
    > "Cubox-$VERSION-SHA256.txt" )

echo
echo "✅ Terminé. Paquets dans $DIST/ :"
ls -lh "$DIST"/ 2>/dev/null
echo
echo "👉 Téléverse ces fichiers dans une *Release* sur la forge."
echo "   Windows     : décompresser le .zip → double-clic sur Cubox.exe (rien à installer)."
echo "   Linux       : décompresser le .tar.gz → ./Cubox.sh"
[ -n "$pkg_built" ] && \
echo "   Arch/pacman : sudo pacman -U $pkg_built"
