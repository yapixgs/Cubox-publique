#!/bin/sh
# Lanceur de Cubox installé par le paquet pacman.
#
# Cubox (comme HMCL) range ses données (comptes, mods, versions de Minecraft,
# configuration) dans un dossier « .hmcl »/« .minecraft » du *répertoire courant*. Le jar
# empaqueté vit dans un chemin système en lecture seule : sans répertoire de travail
# fixe, les données atterriraient là d'où l'on tape « cubox » (le dossier de
# construction, par exemple), éparpillées ou perdues.
#
# On fixe donc un dossier de données stable par utilisateur.
DOSSIER_DONNEES="${XDG_DATA_HOME:-$HOME/.local/share}/cubox"
mkdir -p "$DOSSIER_DONNEES"
cd "$DOSSIER_DONNEES" || exit 1
exec java -jar /usr/share/java/cubox/Cubox.jar "$@"
