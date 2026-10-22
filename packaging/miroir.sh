#!/usr/bin/env bash
#
# miroir.sh — publie une version de Cubox sur le miroir public GitHub (ADR-0041 d'infra).
#
# Usage : packaging/miroir.sh <vX.Y.Z>     (dans le conteneur Arch du workflow « Miroir »)
#
# La forge est la source de vérité ; GitHub est le canal de distribution : la forge exige
# une connexion, même pour un dépôt public (404 anonyme sur l'API, la page et les assets).
# Sans miroir, PERSONNE ne peut télécharger Cubox.
#
#   1. récupère les paquets Windows et Linux joints à la Release de la forge (livraison) ;
#   2. construit le paquet pacman et le dépôt pacman signé (makepkg n'existe que sur Arch) ;
#   3. publie la Release et le code sur le miroir, retire les paquets pacman périmés ;
#   4. vérifie, SANS authentification, que tout est réellement téléchargeable.
#
# Variables : FORGEJO_TOKEN (lecture/écriture de la Release), GH_MIRROR_TOKEN (miroir),
# ARCH_SIGNING_KEY (clé GPG en base64 ; sans elle, le dépôt pacman n'est pas publié).
set -euo pipefail

tag="$1"
version="${tag#v}"
miroir="${MIROIR:-yapixgs/Cubox-publique}"
forge="${GITHUB_SERVER_URL:-https://forge.oxitablock.com}"
depot="${GITHUB_REPOSITORY:-Cloudox/Cubox}"
api="$forge/api/v1/repos/$depot"
: "${FORGEJO_TOKEN:?FORGEJO_TOKEN est requis}"
if [ -z "${GH_MIRROR_TOKEN:-}" ]; then
  echo "secret GH_MIRROR_TOKEN absent : sans miroir, personne ne peut télécharger Cubox." >&2
  exit 1
fi
export GH_TOKEN="$GH_MIRROR_TOKEN"
entete="Authorization: token $FORGEJO_TOKEN"
racine="$(pwd)"
arch_en_echec=""

# Construire le code de la version, pas celui de `main` au moment du lancement. Le dépôt
# change de propriétaire pour makepkg : git doit continuer de l'accepter.
git config --global --add safe.directory '*'
git checkout -q "refs/tags/$tag"

# ── 1. Les paquets de la Release de la forge ────────────────────────────────────────
release="$(curl -fsS -H "$entete" "$api/releases/tags/$tag")"
id="$(jq -r '.id' <<<"$release")"
jq -r '.body // ""' <<<"$release" > /tmp/notes.md
[ -s /tmp/notes.md ] || echo "Cubox $version." > /tmp/notes.md
rm -rf dist depot && mkdir -p dist depot
jq -r '.assets[] | [.name, .browser_download_url] | @tsv' <<<"$release" \
  | while IFS=$'\t' read -r nom adresse; do
      case "$nom" in *.pkg.tar.zst) continue ;; esac
      # Le jeton de compte ne part que vers la forge : une pièce jointe externe
      # (lien vers un autre hôte) le recevrait dans son en-tête.
      case "$adresse" in
        "$forge/$depot/releases/download/"*) ;;
        *) echo "pièce jointe hors de la forge refusée : $nom" >&2; exit 1 ;;
      esac
      echo "  ↓ $nom"
      curl -fsSL -H "$entete" -o "dist/$nom" "$adresse"
    done
packaging/verifier-paquets.sh "$version" dist

# ── 2. Le paquet pacman et le dépôt pacman signé ─────────────────────────────────────
# Sans dépôt pacman, `yay -Syu` ne met PAS Cubox à jour : le paquet n'est sur l'AUR sous
# aucun nom. Il est signé parce que pacman installe en root : le HTTPS prouve qu'on parle
# au bon serveur, pas QUI a fabriqué le paquet.
construire_arch() {
  # makepkg refuse de tourner en root, sans option pour passer outre.
  id -u constructeur >/dev/null 2>&1 || useradd -m constructeur
  chown -R constructeur:constructeur "$racine"
  # `env -u GITHUB_SHA` : le runner l'exporte, et HMCL/build.gradle.kts en ferait
  # « 1.4.0.unofficial-1b98053 » — le numéro affiché dans la fenêtre du lanceur.
  # `su` transmet l'environnement : les secrets n'ont rien à faire dans la construction.
  su constructeur -c "cd '$racine/packaging/aur' && rm -f ./*.pkg.tar.zst \
    && env -u GITHUB_SHA -u BUILD_NUMBER -u FORGEJO_TOKEN -u GH_TOKEN -u GH_MIRROR_TOKEN \
       -u ARCH_SIGNING_KEY VERSION_ROOT='$version' makepkg -Cf --noconfirm" \
    || return 1
  local jar
  jar="$(find packaging/aur -name 'Cubox-*.jar' | head -n1)"
  [ -n "$jar" ] || return 1
  jar="$(basename "$jar" .jar)"
  if [ "${jar#Cubox-}" != "$version" ]; then
    echo "le jar annonce « ${jar#Cubox-} » au lieu de « $version »" >&2
    return 1
  fi
}

signer_depot() {
  local paquet="$1" sain empreinte
  # GitHub remplace le « : » de l'epoch (1:1.4.0…) par un « . » dans les noms d'assets ;
  # pacman télécharge le nom inscrit dans la base : on renomme nous-mêmes.
  sain="$(basename "$paquet" | tr ':' '-')"
  cp "$paquet" "depot/$sain"
  export GNUPGHOME=/tmp/gnupg
  mkdir -p "$GNUPGHOME" && chmod 700 "$GNUPGHOME"
  printf '%s' "$ARCH_SIGNING_KEY" | base64 -d | gpg --batch --quiet --import
  empreinte="$(gpg --batch --with-colons --list-secret-keys | awk -F: '/^fpr:/ {print $10; exit}')"
  echo "clé de signature : $empreinte"
  (
    cd depot
    gpg --batch --yes --detach-sign --no-armor "$sain"
    # `-s` signe aussi la base : sinon remplacer la base suffirait à tromper pacman.
    repo-add -s -v cubox.db.tar.gz "$sain"
    # repo-add produit des liens symboliques, que GitHub ne sait pas téléverser.
    for lien in cubox.db cubox.db.sig cubox.files cubox.files.sig; do
      [ -L "$lien" ] && cp --remove-destination "$(readlink -f "$lien")" "$lien"
    done
    gpg --batch --armor --export "$empreinte" > cubox-signing-key.asc
  )
}

paquet=""
if construire_arch; then
  paquet="$(find packaging/aur -maxdepth 1 -name 'cubox-*.pkg.tar.zst' | head -n1)"
  nom="$(basename "$paquet")"
  # Sur la forge, le nom avec « : » est valide : c'est la référence.
  ancien="$(jq -r --arg n "$nom" '.assets[] | select(.name == $n) | .id' <<<"$release")"
  [ -z "$ancien" ] || curl -fsS -X DELETE -H "$entete" "$api/releases/$id/assets/$ancien" >/dev/null
  curl -fsS -X POST -H "$entete" -F "attachment=@$paquet" \
    "$api/releases/$id/assets?name=$nom" >/dev/null
  echo "paquet pacman joint à la Release de la forge : $nom"
  if [ -n "${ARCH_SIGNING_KEY:-}" ]; then
    signer_depot "$paquet"
  else
    # Publier un dépôt non signé serait pire que pas de dépôt : pacman installe en root.
    echo "::warning::ARCH_SIGNING_KEY absent — dépôt pacman NON publié"
  fi
else
  # Le paquet pacman est un confort : Windows et Linux partent quand même, mais l'échec
  # reste visible (le job finit en erreur).
  arch_en_echec="oui"
  echo "::error::paquet pacman en échec — Windows et Linux sont tout de même miroités"
fi

# ── 3. La Release et le code sur le miroir ───────────────────────────────────────────
if gh release view "$tag" --repo "$miroir" >/dev/null 2>&1; then
  gh release edit "$tag" --repo "$miroir" --notes-file /tmp/notes.md
else
  gh release create "$tag" --repo "$miroir" --title "Cubox $version" --notes-file /tmp/notes.md
fi
gh release upload "$tag" dist/* --repo "$miroir" --clobber
if [ -n "$(ls depot)" ]; then
  # Seul le dépôt signé part sur GitHub : le paquet brut y serait un doublon renommé.
  gh release upload "$tag" depot/* --repo "$miroir" --clobber
  attendus="$(ls depot)"
  # `--clobber` remplace un asset de même nom, il ne retire pas les périmés.
  gh release view "$tag" --repo "$miroir" --json assets --jq '.assets[].name' \
    | { grep -E '^cubox-.*\.pkg\.tar\.zst(\.sig)?$' || true; } \
    | while read -r asset; do
        if ! grep -qxF "$asset" <<<"$attendus"; then
          gh release delete-asset "$tag" "$asset" --repo "$miroir" --yes
          echo "asset périmé retiré du miroir : $asset"
        fi
      done
elif [ -n "$paquet" ]; then
  gh release upload "$tag" "$paquet" --repo "$miroir" --clobber
fi

# Le code aussi : le lanceur et le site renvoient leurs liens publics (README, guide,
# CHANGELOG, licence, tickets) vers le miroir. `--force` : le miroir est un reflet.
git -c user.name="Cubox CI" -c user.email="ci@cloudox.invalid" \
  push --force "https://x-access-token:${GH_TOKEN}@github.com/${miroir}.git" \
  "HEAD:refs/heads/main" "refs/tags/$tag"
echo "code et tag $tag miroités vers $miroir"

# ── 4. Vérification SANS authentification, comme un visiteur ────────────────────────
# Vérifier avec un jeton ne prouverait rien : c'est l'erreur qui avait laissé croire
# que la forge suffisait.
curl -fsS -H 'User-Agent: cubox-ci' "https://api.github.com/repos/$miroir/releases/tags/$tag" \
  | jq -r '.tag_name, (.assets[] | "  " + .name + "  " + (.size | tostring) + " o")'
code="$(curl -sSL -o /dev/null -w '%{http_code}' \
  "https://github.com/$miroir/releases/download/$tag/Cubox-$version-SHA256.txt")"
[ "$code" = "200" ] || { echo "téléchargement anonyme : HTTP $code" >&2; exit 1; }
# Le lanceur et le site pointent vers ces pages : absentes, ce sont des liens morts
# dans un binaire distribué.
for fichier in README.md CHANGELOG.md LICENSE docs/GUIDE_MINECRAFT_DEBUTANT.md \
               docs/ROADMAP.md docs/EULA.md docs/DEPOT-PACMAN.md; do
  code="$(curl -sSL -o /dev/null -w '%{http_code}' \
    "https://raw.githubusercontent.com/$miroir/$tag/$fichier")"
  printf '  %-40s %s\n' "$fichier" "$code"
  [ "$code" = "200" ] || { echo "$fichier absent du miroir" >&2; exit 1; }
done
echo "✓ Cubox $version téléchargeable anonymement : https://github.com/$miroir/releases/tag/$tag"

if [ -n "$arch_en_echec" ]; then
  exit 1
fi
