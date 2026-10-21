#!/usr/bin/env bash
#
# publier-forge.sh — joint les paquets du lanceur à la Release de la forge, puis lance le
# miroir public (workflow « Miroir », ADR-0041 d'infra).
#
# Usage : packaging/publier-forge.sh <vX.Y.Z> <dossier des paquets>
#
# Appelé par `just publication`, après `normes publier` qui a posé le tag et créé la
# Release. Le miroir est un workflow à part (dérogation R8.1 de cloudox.toml) : lui seul
# reçoit les secrets du miroir GitHub et de la signature du dépôt pacman.
set -euo pipefail

tag="$1"
dossier="$2"
: "${FORGEJO_TOKEN:?FORGEJO_TOKEN est requis}"
forge="${GITHUB_SERVER_URL:-https://forge.oxitablock.com}"
depot="${GITHUB_REPOSITORY:-Cloudox/Cubox}"
api="$forge/api/v1/repos/$depot"
entete="Authorization: token $FORGEJO_TOKEN"

json() { python3 -c "import json, sys; print(json.load(sys.stdin)$1)"; }

id="$(curl -fsS -H "$entete" "$api/releases/tags/$tag" | json "['id']")"
echo "Release $tag : id $id"

# Idempotent : relancer la publication remplace les fichiers, elle n'échoue pas.
existants="$(curl -fsS -H "$entete" "$api/releases/$id/assets?limit=50&page=1" \
  | python3 -c 'import json, sys; [print(a["id"], a["name"]) for a in json.load(sys.stdin)]')"
for fichier in "$dossier"/*; do
  nom="$(basename "$fichier")"
  ancien="$(awk -v n="$nom" '$2 == n {print $1}' <<<"$existants")"
  if [ -n "$ancien" ]; then
    curl -fsS -X DELETE -H "$entete" "$api/releases/$id/assets/$ancien" >/dev/null
  fi
  echo "  ↑ $nom"
  curl -fsS -X POST -H "$entete" -F "attachment=@$fichier" \
    "$api/releases/$id/assets?name=$nom" >/dev/null
done

# Le miroir public : sans lui, personne ne peut télécharger Cubox (la forge refuse
# l'accès anonyme). Un échec ici arrête la livraison, il ne passe pas en silence.
curl -fsS -X POST -H "$entete" -H 'Content-Type: application/json' \
  -d "{\"ref\": \"main\", \"inputs\": {\"version\": \"$tag\"}}" \
  "$api/actions/workflows/miroir.yml/dispatches"
echo "miroir public lancé pour $tag (workflow Miroir)"
