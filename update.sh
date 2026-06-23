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

# Le dépôt est public : on tire en ANONYME en désactivant tout credential helper.
# Évite l'erreur "identifiants invalides ou expirés" causée par un ancien
# identifiant mis en cache lors du premier clone.
GIT_TERMINAL_PROMPT=0 git -c credential.helper= pull
cd packaging/aur
makepkg -sif
