# Référentiel Cloudox (R8.2) — fichier canonique, ne pas modifier : `normes synchro` le réécrit.
# Chaque recette délègue à l'outil `normes` : la CI et les postes lancent la même chose.
# Le `justfile` du dépôt importe ce fichier et ne fait qu'AJOUTER les recettes du produit.

set shell := ["bash", "-euo", "pipefail", "-c"]

# L'outil du référentiel. Seul le dépôt `normes` le remplace, par ses propres sources.
normes := "normes"

# Lister les recettes.
default:
    @just --list

# Lancer tous les contrôles de la CI, dans l'ordre de la CI (R8.3).
ci: conformite qualite tests e2e construction

# Vérifier la conformité au référentiel Cloudox (R8.3).
conformite:
    {{normes}} verifier

# Analyse statique, format, types et recherche de secrets (R8.3).
qualite:
    {{normes}} tache qualite

# Tests unitaires et d'intégration, avec couverture (R8.3).
tests:
    {{normes}} tache tests

# Parcours de bout en bout dans le navigateur (R8.3).
e2e:
    {{normes}} tache e2e

# Construire les images sans les publier, puis les analyser (R8.3).
construction:
    {{normes}} tache construction

# Afficher la version à livrer, ou rien s'il n'y a rien à livrer (R4.9).
version:
    @{{normes}} version suivante

# Construire et publier les images d'une version ; un tag publié est immuable (R8.5, R9.6).
images version:
    {{normes}} tache images --version {{version}}

# Poser le tag et publier la Release de la forge (R4.9, R8.5).
publication version:
    {{normes}} publier {{version}}

# Ouvrir la PR de mise en prod dans infra (R8.5, R10.3).
deploiement version:
    {{normes}} deployer {{version}}

# Réécrire les fichiers canoniques depuis la version épinglée des normes (R8.6).
synchro:
    {{normes}} synchro
