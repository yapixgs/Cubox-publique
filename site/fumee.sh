#!/usr/bin/env bash
#
# fumee.sh — test de fumée de l'image du site (appelé par `just construction`).
#
# Usage : site/fumee.sh <image>
#
# Attrape ce que Trivy et les tests du site ne voient pas : une variable nginx non
# substituée (nginx démarre mais le relais est cassé), l'empreinte de l'import map absente
# de la CSP (page blanche), un conteneur root (refusé par le namespace `restricted`).
set -euo pipefail

image="$1"
nom="fumee-site-$$"
echec=""
docker run --rm -d --name "$nom" "$image" >/dev/null
trap 'docker logs "$nom" 2>&1 | tail -20; docker stop "$nom" >/dev/null 2>&1 || true' EXIT

pret=""
for _ in $(seq 15); do
  if docker exec "$nom" wget -qO- http://127.0.0.1:8080/healthz >/dev/null 2>&1; then
    pret="oui"
    break
  fi
  sleep 2
done
[ -n "$pret" ] || { echo "ÉCHEC : l'image ne répond pas en 30 s" >&2; exit 1; }

docker exec "$nom" wget -qO- http://127.0.0.1:8080/ | grep -q 'Cubox' \
  || { echo "ÉCHEC : la page d'accueil ne contient pas « Cubox »"; echec="oui"; }
docker exec "$nom" wget -qO- http://127.0.0.1:8080/install-arch.sh | grep -q 'pacman' \
  || { echo "ÉCHEC : /install-arch.sh n'est pas servi"; echec="oui"; }
if docker exec "$nom" grep -q 'CUBOX_RELEASES_BASE' /etc/nginx/conf.d/default.conf; then
  echo "ÉCHEC : variables CUBOX_* non substituées dans la configuration nginx"
  echec="oui"
fi
docker exec "$nom" grep -q "script-src 'self' 'sha256-" /etc/nginx/securite.conf \
  || { echo "ÉCHEC : empreinte de l'import map absente de la CSP"; echec="oui"; }
uid="$(docker exec "$nom" id -u)"
[ "$uid" = "10001" ] || { echo "ÉCHEC : UID $uid au lieu de 10001"; echec="oui"; }

[ -z "$echec" ] || exit 1
echo "✓ test de fumée du site"
