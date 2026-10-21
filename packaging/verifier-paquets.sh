#!/usr/bin/env bash
#
# verifier-paquets.sh — vérifie les archives produites par make-release.sh.
#
# Usage : packaging/verifier-paquets.sh <version> <dossier>
#
# Une archive à laquelle il manque l'installeur ou le Java embarqué, c'est exactement
# la régression que l'utilisateur découvrirait à notre place.
set -euo pipefail

version="$1"
dossier="$2"
cd "$dossier"
ls -lh

manque() { echo "MANQUE : $1" >&2; exit 1; }

zip="Cubox-$version-windows-x64.zip"
tar="Cubox-$version-linux-x64.tar.gz"
[ -s "$zip" ] || manque "$zip"
[ -s "$tar" ] || manque "$tar"

contenu_zip="$(unzip -l "$zip")"
grep -q 'Installer\.exe' <<<"$contenu_zip" || manque "Installer.exe dans $zip"
grep -q 'jre-x64/bin/java\.exe' <<<"$contenu_zip" || manque "jre-x64 (Windows) dans $zip"

contenu_tar="$(tar -tzf "$tar")"
grep -q 'install\.sh' <<<"$contenu_tar" || manque "install.sh dans $tar"
grep -q 'jre-x64/bin/java' <<<"$contenu_tar" || manque "jre-x64 (Linux) dans $tar"

sha256sum -c "Cubox-$version-SHA256.txt" || manque "sommes de contrôle valides"
echo "archives conformes ($version)"
