#!/bin/sh
# Met à jour Cubox depuis la forge et le réinstalle.
#
# Pourquoi ce script : makepkg réécrit la ligne « pkgver= » dans le PKGBUILD à
# chaque build (version dynamique tirée du git). Cette modification locale
# bloque ensuite « git pull » ("vos modifications locales seraient écrasées").
# On annule donc cette réécriture avant de tirer les mises à jour.
set -e
cd "$(dirname "$0")"

# Annule la réécriture locale du PKGBUILD par makepkg (sera régénérée au build).
git checkout -- packaging/aur/PKGBUILD 2>/dev/null || true

# ⚠️ Le dépôt est marqué public, mais la forge EXIGE QUAND MÊME UNE CONNEXION.
# Mesuré depuis un client sans identifiants : 404 sur l'API, sur la page du
# dépôt et sur les assets. Tirer en anonyme ne peut donc pas fonctionner —
# l'ancienne version de ce script désactivait le credential helper, ce qui
# garantissait l'échec au lieu de l'éviter.
#
# On laisse donc git utiliser les identifiants configurés. Si tu n'en as pas :
#   git config --global credential.helper store
# puis un `git pull` interactif une fois.
git pull
cd packaging/aur
makepkg -sif
