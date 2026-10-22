# Le lanceur Cubox : compilation Gradle, tests, paquets Windows et Linux (R9.1 : par la CI).
#
# Le lanceur n'est pas une image de conteneur : ce Dockerfile ne sert qu'à fabriquer, dans
# l'outil commun de la CI (Docker), ce qui exige un JDK 21 et NSIS. Contexte = racine du dépôt.
# Les recettes du justfile le pilotent :
#
#     docker buildx build -f packaging/Dockerfile --target paquets-sortie \
#       --build-arg VERSION=1.4.0 --output type=local,dest=dist .
#
# Cibles : `verification` (scripts shell), `tests` (Gradle), `paquets-sortie` (archives).

FROM docker.io/library/eclipse-temurin:21.0.12.1_1-jdk-noble@sha256:107215954359f1ab0be058a247d7c64ed6e69c71c1682d471d38ef751ec8e964 AS outils
RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends \
      git ca-certificates curl zip unzip nsis shellcheck \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /cubox
COPY . .
# Gradle ne survit pas au conteneur : pas de démon.
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false"

# ── Scripts d'installation : une faute de frappe qui n'explose qu'à l'exécution se paie
#    en désinstallations ─────────────────────────────────────────────────────────────
FROM outils AS verification
RUN set -eu; \
    for script in packaging/installer/install.sh packaging/installer/uninstall.sh \
                  packaging/fabriquer-paquets.sh packaging/arch/install-arch.sh \
                  packaging/verifier-paquets.sh packaging/publier-forge.sh \
                  packaging/miroir.sh; do \
      bash -n "$script"; \
    done; \
    shellcheck -S warning packaging/installer/install.sh packaging/installer/uninstall.sh \
      packaging/arch/install-arch.sh packaging/verifier-paquets.sh \
      packaging/publier-forge.sh packaging/miroir.sh; \
    cd packaging/installer && makensis -V2 -DVERSION=ci cubox.nsi && test -s Installer.exe

# ── Tests du lanceur (JUnit) ─────────────────────────────────────────────────────────
FROM outils AS tests
RUN ./gradlew --stacktrace test

# ── Paquets distribuables, chacun avec son Java 21 ───────────────────────────────────
FROM outils AS paquets
ARG VERSION=0.0.0-dev
# VERSION_ROOT fixe le numéro affiché dans la fenêtre du lanceur (HMCL/build.gradle.kts).
RUN VERSION_ROOT="${VERSION}" ./packaging/fabriquer-paquets.sh "${VERSION}" \
 && ./packaging/verifier-paquets.sh "${VERSION}" dist

FROM scratch AS paquets-sortie
COPY --from=paquets /cubox/dist/ /
