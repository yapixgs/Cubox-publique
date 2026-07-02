#!/usr/bin/env bash
#
# publish-github.sh — mirroir public de Cubox vers GitHub.
#
# Ce script reflète SUR GITHUB :
#   - la branche `main` (et elle seule — aucune branche de dev) ;
#   - TOUTES les Releases de la forge (tags + descriptions + fichiers binaires).
#
# Pourquoi : la forge oxitablock exige une connexion (tes amis ont un 404 sans
# compte). GitHub, lui, laisse télécharger sans compte → tes potes récupèrent
# Cubox librement sur https://github.com/<ton-pseudo>/<repo>/releases.
#
# Idempotent : tu peux le relancer quand tu veux, il met à jour main et
# (ré)upload les fichiers manquants des releases.
#
# ─────────────────────────────────────────────────────────────────────────────
# PRÉREQUIS (une seule fois)
#   1. Installe GitHub CLI :        sudo pacman -S github-cli
#   2. Connecte-toi à GitHub :      gh auth login        (choisis HTTPS)
#      puis active git :            gh auth setup-git
#   3. FORGE_TOKEN est OPTIONNEL : le dépôt Cubox de la forge est public, donc
#      les fichiers des releases se téléchargent sans jeton. Ne renseigne un
#      FORGE_TOKEN (portée lecture) que si tu passes le dépôt en privé un jour.
#
# USAGE
#   GITHUB_REPO="TonPseudo/Cubox" bash packaging/publish-github.sh
#   # (FORGE_TOKEN="xxxxx" seulement si le dépôt de la forge devient privé)
#
#   (ou renseigne les valeurs par défaut ci-dessous une fois pour toutes)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# --- Réglages ---------------------------------------------------------------
# Dépôt GitHub cible « pseudo/repo ». Valeur par défaut = le mirroir public de
# Yapix ; surchargeable via la variable d'environnement GITHUB_REPO.
GITHUB_REPO="${GITHUB_REPO:-yapixgs/Cubox-publique}"

# Dépôt source sur la forge.
FORGE_BASE="${FORGE_BASE:-https://forge.oxitablock.com}"
FORGE_OWNER="${FORGE_OWNER:-Yapix839}"
FORGE_REPO="${FORGE_REPO:-Cubox}"

# Jeton de lecture de la forge — OPTIONNEL (le dépôt est public). Utile
# uniquement si tu passes le dépôt de la forge en privé.
FORGE_TOKEN="${FORGE_TOKEN:-}"

# En-tête d'auth forge : ajouté SEULEMENT si un jeton non vide est fourni.
# (Évite le « 401 » quand on laisse le placeholder ou aucun jeton.)
FORGE_AUTH=()
[ -n "$FORGE_TOKEN" ] && FORGE_AUTH=(-H "Authorization: token $FORGE_TOKEN")

# --- Vérifications ----------------------------------------------------------
need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Outil manquant : $1"; exit 1; }; }
need git; need curl; need jq; need gh

[ -n "$GITHUB_REPO" ] || { echo "❌ GITHUB_REPO non défini (ex. export GITHUB_REPO=\"TonPseudo/Cubox\")"; exit 1; }
[ -n "$FORGE_TOKEN" ] || echo "   ℹ️  Pas de FORGE_TOKEN : dépôt public → téléchargement anonyme des releases."

gh auth status >/dev/null 2>&1 || { echo "❌ GitHub CLI non connecté. Lance : gh auth login && gh auth setup-git"; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

api() { curl -fsSL "${FORGE_AUTH[@]}" "$@"; }

# --- 1/2 : créer le dépôt GitHub s'il n'existe pas, puis pousser main --------
echo "🌍 1/2  Branche main → GitHub ($GITHUB_REPO)…"
if ! gh repo view "$GITHUB_REPO" >/dev/null 2>&1; then
  echo "   ℹ️  Le dépôt GitHub n'existe pas → création (public)…"
  gh repo create "$GITHUB_REPO" --public \
    --description "Cubox — launcher Minecraft hors-ligne (mirroir public)" >/dev/null
fi

# On pousse UNIQUEMENT main (aucune branche de dev). --force : main GitHub
# reflète exactement main de la forge. On s'authentifie avec le jeton de `gh`
# (fonctionne que tu aies choisi SSH ou HTTPS dans `gh auth login`).
gh_token="$(gh auth token)"
git push --force "https://x-access-token:${gh_token}@github.com/$GITHUB_REPO.git" "main:main"
echo "   ✅ main poussée."

# --- 2/2 : mirroir de toutes les Releases -----------------------------------
echo "📦 2/2  Releases de la forge → GitHub…"
releases_json="$(api "$FORGE_BASE/api/v1/repos/$FORGE_OWNER/$FORGE_REPO/releases?limit=100")"
count="$(echo "$releases_json" | jq 'length')"
echo "   $count release(s) trouvée(s) sur la forge."

# On traite de la plus ancienne à la plus récente (ordre chrono propre).
echo "$releases_json" | jq -c 'reverse[]' | while read -r rel; do
  tag="$(echo "$rel"  | jq -r '.tag_name')"
  name="$(echo "$rel" | jq -r '.name // .tag_name')"
  body="$(echo "$rel" | jq -r '.body // ""')"
  prerelease="$(echo "$rel" | jq -r '.prerelease')"

  echo "   ── $tag («$name»)…"
  tmp="$(mktemp -d)"

  # Télécharge chaque asset de la release (dépôt public → sans jeton), en
  # nettoyant le nom de fichier (GitHub n'aime pas le « : » de l'epoch pacman).
  # Un échec sur un fichier n'interrompt pas tout le mirroir : on prévient et
  # on continue (la release est quand même (re)créée avec ses notes).
  echo "$rel" | jq -r '.assets[]?.browser_download_url' | while read -r url; do
    [ -n "$url" ] || continue
    raw="$(basename "$url")"
    safe="${raw//:/-}"           # cubox-1:1.2…  →  cubox-1-1.2…
    echo "        ⬇️  $raw"
    if ! curl -fsSL "${FORGE_AUTH[@]}" -o "$tmp/$safe" "$url"; then
      echo "        ⚠️  échec du téléchargement de $raw (ignoré)"
      rm -f "$tmp/$safe"
    fi
  done

  files=("$tmp"/*)
  pre_flag=()
  [ "$prerelease" = "true" ] && pre_flag=(--prerelease)

  if gh release view "$tag" --repo "$GITHUB_REPO" >/dev/null 2>&1; then
    echo "        ♻️  release GitHub existante → mise à jour des fichiers"
    if [ -e "${files[0]}" ]; then
      gh release upload "$tag" "${files[@]}" --repo "$GITHUB_REPO" --clobber
    fi
    gh release edit "$tag" --repo "$GITHUB_REPO" --title "$name" --notes "$body" "${pre_flag[@]}" >/dev/null
  else
    echo "        ✨ création de la release GitHub"
    if [ -e "${files[0]}" ]; then
      gh release create "$tag" "${files[@]}" --repo "$GITHUB_REPO" \
        --title "$name" --notes "$body" "${pre_flag[@]}" >/dev/null
    else
      gh release create "$tag" --repo "$GITHUB_REPO" \
        --title "$name" --notes "$body" "${pre_flag[@]}" >/dev/null
    fi
  fi

  rm -rf "$tmp"
done

echo
echo "✅ Terminé. Mirroir public : https://github.com/$GITHUB_REPO"
echo "   Tes amis téléchargent ici (sans compte) : https://github.com/$GITHUB_REPO/releases"
