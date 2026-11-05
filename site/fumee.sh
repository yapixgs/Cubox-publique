#!/usr/bin/env bash
#
# fumee.sh — test de fumée de l'image du site (appelé par `just construction`, après
# l'assemblage par normes).
#
# Usage : site/fumee.sh
#
# Le runner ne lance pas de conteneur : l'image n'empile que des fichiers (R9.3), on vérifie
# donc ce qu'elle empile et comment elle démarre. Attrape ce que Trivy et les tests du site
# ne voient pas : l'empreinte de l'import map absente de la CSP (page blanche), une page ou
# un script d'installation manquants, le filtre de substitution des variables nginx perdu
# (relais cassé), un conteneur root (refusé par le namespace `restricted`).
set -euo pipefail
cd "$(dirname "$0")"
echec=""
grep -q 'Cubox' dist/index.html \
  || { echo "ÉCHEC : la page d'accueil ne contient pas « Cubox »"; echec="oui"; }
grep -q 'pacman' dist/install-arch.sh \
  || { echo "ÉCHEC : /install-arch.sh n'est pas construit"; echec="oui"; }
[ ! -e dist/importmap.sha256 ] \
  || { echo "ÉCHEC : l'empreinte de l'import map serait servie"; echec="oui"; }
grep -q "script-src 'self' 'sha256-" .construction/securite.conf \
  || { echo "ÉCHEC : empreinte de l'import map absente de la CSP"; echec="oui"; }
grep -q '^COPY .construction/securite.conf *\/etc\/nginx\/securite.conf$' Dockerfile \
  || { echo "ÉCHEC : la CSP préparée n'est pas copiée dans l'image"; echec="oui"; }
grep -q 'NGINX_ENVSUBST_FILTER="CUBOX_|NGINX_LOCAL_RESOLVERS"' Dockerfile \
  || { echo "ÉCHEC : filtre de substitution des variables nginx absent"; echec="oui"; }
grep -q '^USER 10001:10001$' Dockerfile \
  || { echo "ÉCHEC : l'image ne tourne pas en UID 10001"; echec="oui"; }
[ -z "$echec" ] || exit 1
echo "✓ test de fumée du site"
