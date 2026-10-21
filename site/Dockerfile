# Page publique de téléchargement de Cubox (R9.3, gabarit « frontend »).
#
# La CI construit le site (`npm run build`, avec le jeton du registre privé) ; l'image ne
# fait que copier `dist/` : aucun secret n'entre dans une couche. Contexte = `site/`.
#
#     npm ci && npm run build && docker build --tag cubox-site .

# Image de base officielle amont, épinglée par empreinte (R9.3 ; règle 4 de
# Cloudox/infra/AGENTS.md : logiciel tiers, image officielle, aucun miroir).
FROM docker.io/library/nginx:1.30.6-alpine@sha256:970364228b1e4f932abc22d321932816782cca8a20b85a77552a7cfe9acfb3b5

# Le namespace applique `pod-security.kubernetes.io/enforce: restricted` :
# le conteneur tourne en UID 10001 avec une racine en lecture seule.
ARG UID=10001
ARG GID=10001
ARG VERSION=0.0.0-dev

# Source des téléchargements publics : le miroir GitHub, pas la forge.
# La forge exige une connexion même pour un dépôt public (404 anonyme sur
# l'API, la page du dépôt ET les assets — mesuré, ADR-0041 d'infra).
# Surchargeable par le Deployment : la page doit pouvoir suivre un renommage
# sans reconstruction.
ENV CUBOX_RELEASES_BASE="https://api.github.com" \
    CUBOX_RELEASES_HOST="api.github.com" \
    CUBOX_RELEASES_REPO="yapixgs/Cubox-publique"

# ⚠️ Sans ce filtre, l'entrypoint substitue TOUTES les variables shell du
# template — y compris `$uri` et `$upstream_cache_status`, qui deviendraient
# vides. La configuration serait alors invalide, ou pire : valide et fausse.
# NGINX_LOCAL_RESOLVERS : le serveur DNS du pod, posé par l'entrypoint
# (15-local-resolvers.envsh) quand NGINX_ENTRYPOINT_LOCAL_RESOLVERS est défini ;
# il sert au `resolver` du relais GitHub (résolution dynamique, voir le template).
ENV NGINX_ENVSUBST_FILTER="CUBOX_|NGINX_LOCAL_RESOLVERS" \
    NGINX_ENTRYPOINT_LOCAL_RESOLVERS=1

COPY nginx/nginx-main.conf         /etc/nginx/nginx.conf
COPY nginx/default.conf.template   /etc/nginx/templates/default.conf.template
# `dist/` contient aussi le logo (HMCL/image/cubox.png) et le script d'installation
# Arch (packaging/arch/install-arch.sh), copiés par vite.config.js : l'adresse
# /install-arch.sh est celle qu'on donne aux gens, elle doit rester stable.
COPY dist/                         /usr/share/nginx/html/
COPY nginx/securite.conf           /tmp/securite.conf

# L'import map est le seul script inline : son empreinte, calculée au build du
# site, entre dans la CSP. Sans elle, le navigateur la refuse et la page reste
# blanche. L'entrypoint officiel écrit le résultat de la substitution dans
# /etc/nginx/conf.d/ : ce dossier doit appartenir à l'utilisateur du conteneur.
RUN set -eu; \
    hash="$(cat /usr/share/nginx/html/importmap.sha256)"; \
    case "$hash" in "'sha256-"*"'") ;; *) echo "empreinte d'import map illisible : $hash" >&2; exit 1 ;; esac; \
    sed "s|@IMPORTMAP_SHA256@|$hash|" /tmp/securite.conf > /etc/nginx/securite.conf; \
    if grep -q '@IMPORTMAP_SHA256@' /etc/nginx/securite.conf; then exit 1; fi; \
    rm /tmp/securite.conf /usr/share/nginx/html/importmap.sha256; \
    test -s /usr/share/nginx/html/cubox.png; \
    test -s /usr/share/nginx/html/install-arch.sh; \
    chown -R "${UID}:${GID}" /usr/share/nginx/html /etc/nginx/conf.d

LABEL org.opencontainers.image.title="cloudox/cubox-site"

USER 10001:10001

# 8080 et pas 80 : un processus non privilégié ne peut pas se lier sous 1024.
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz >/dev/null || exit 1

CMD ["nginx", "-g", "daemon off;"]
