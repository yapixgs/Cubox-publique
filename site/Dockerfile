# Page publique de téléchargement de Cubox (R9.3, gabarit « frontend »).
#
# La CI construit le site (`npm run build`, avec le jeton du registre privé) et prépare la
# configuration nginx (site/preparer-nginx.mjs) ; l'image ne fait qu'empiler les fichiers :
# aucun secret n'entre dans une couche, rien ne s'y exécute. Contexte = `site/`.

# Image de base officielle amont, épinglée par empreinte (R9.3 ; règle 4 de
# Cloudox/infra/AGENTS.md : logiciel tiers, image officielle, servie par le cache de Zot).
FROM docker.io/library/nginx:1.30.6-alpine@sha256:970364228b1e4f932abc22d321932816782cca8a20b85a77552a7cfe9acfb3b5

ARG VERSION=0.0.0-dev

# Source des téléchargements publics : le miroir GitHub, pas la forge.
# La forge exige une connexion même pour un dépôt public (ADR-0041 d'infra).
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
# CSP avec l'empreinte de l'import map, préparée par la CI.
COPY .construction/securite.conf   /etc/nginx/securite.conf
# `dist/` contient aussi le logo (HMCL/image/cubox.png) et le script d'installation
# Arch (packaging/arch/install-arch.sh), copiés par vite.config.js.
COPY dist/                         /usr/share/nginx/html/

LABEL org.opencontainers.image.title="cloudox/cubox-site"

# Le namespace applique `pod-security.kubernetes.io/enforce: restricted`. L'entrypoint
# écrit dans /etc/nginx/conf.d, un volume inscriptible dans le Deployment.
USER 10001:10001

# 8080 et pas 80 : un processus non privilégié ne peut pas se lier sous 1024.
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
