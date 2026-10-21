# Cubox — recettes du produit (R8.2).
#
# Les recettes communes viennent de cloudox.just. Cubox est un fork de HMCL : son lanceur
# se construit avec Gradle et son site n'est ni un `backend` ni un `frontend` du gabarit
# (dérogations R3.2 et R4.3 de cloudox.toml). Les recettes ci-dessous REMPLACENT donc
# celles de cloudox.just du même nom, en appelant toujours les tâches canoniques pour le
# site (site/outil_normes.py) et Docker pour le lanceur (packaging/Dockerfile).
set allow-duplicate-recipes

import 'cloudox.just'

# L'outil normes, avec le site déclaré comme unité.
normes-site := "\"$(dirname \"$(readlink -f \"$(command -v " + normes + ")\")\")/python\" site/outil_normes.py"

# Construire une cible du lanceur dans Docker (packaging/Dockerfile).
lanceur := "docker buildx build --progress plain --file packaging/Dockerfile"

# Le site sur http://127.0.0.1:5181, rechargé à chaque modification (R11.7).
dev:
    cd site && npm ci --no-audit --no-fund && npm run dev

# Le site tel qu'en production, sur http://127.0.0.1:8080 (R11.7).
dev-image:
    cd site && npm ci --no-audit --no-fund && npm run build
    docker compose up --build

# Analyse statique : secrets, site (svelte-check), scripts shell et installeur Windows (R8.3).
qualite:
    {{normes-site}} tache qualite
    {{lanceur}} --target verification .

# Tests du site (vitest) et du lanceur (JUnit) (R8.3).
tests:
    {{normes-site}} tache tests
    {{lanceur}} --target tests .

# Parcours du site dans le navigateur, API simulée (R8.3).
e2e:
    {{normes-site}} tache e2e

# Image du site (Trivy, test de fumée) et paquets du lanceur, sans rien publier (R8.3).
construction:
    {{normes-site}} tache construction
    site/fumee.sh {{IMAGE_SITE}}:ci
    just paquets 0.0.0-ci

# Construire les paquets Windows et Linux du lanceur dans dist/, vérifiés dans le build.
paquets version:
    rm -rf dist
    {{lanceur}} --target paquets-sortie --build-arg VERSION={{version}} \
      --output type=local,dest=dist .
    ls -lh dist

# Publier l'image du site ; un tag publié est immuable (R8.5, R9.6).
images version:
    {{normes-site}} tache images --version {{version}}

# Paquets du lanceur, tag et Release de la forge, puis miroir public (R4.9, R8.5, ADR-0041).
publication version:
    just paquets {{trim_start_match(version, "v")}}
    {{normes}} publier {{version}}
    packaging/publier-forge.sh {{version}} dist

# Ouvrir la PR de mise en prod du site dans infra (R8.5, R10.3).
deploiement version:
    {{normes-site}} deployer {{version}}

# Miroir public GitHub d'une version publiée (workflow Miroir, ADR-0041 d'infra).
miroir version:
    packaging/miroir.sh {{version}}

IMAGE_SITE := "forge.oxitablock.com/cloudox/cubox-site"
