# Page publique de téléchargement de Cubox.
#
# Contexte de build = RACINE du dépôt (pas site/), pour reprendre le logo déjà
# versionné dans HMCL/image/ au lieu d'en dupliquer une copie :
#
#     docker build --file site/Dockerfile --secret id=npm_token,env=CLOUDOX_NPM_TOKEN .
#
# Exige BuildKit (secret monté, et site/Dockerfile.dockerignore qui limite le
# contexte aux fichiers réellement copiés).

# ── Étape 1 : le site Svelte (site/web) ──────────────────────────────────────
# Même image épinglée que le socle Cloudox.
FROM docker.io/library/node:22.23.0-bookworm-slim@sha256:d9f850096136edbc402debdd8729579a288aac64574ada0ff4db26b6ae58b0b2 AS web
WORKDIR /web
COPY site/web/package.json site/web/package-lock.json site/web/.npmrc ./
# @cloudox/socle vient du registre npm privé de la forge. Le jeton est un
# secret BuildKit : lu dans CETTE commande seulement, il n'atterrit dans aucune
# couche (.npmrc ne contient que la référence ${CLOUDOX_NPM_TOKEN}).
RUN --mount=type=secret,id=npm_token,required=true \
    CLOUDOX_NPM_TOKEN="$(cat /run/secrets/npm_token)" npm ci --no-audit --no-fund
COPY site/web/index.html site/web/vite.config.js site/web/jsconfig.json ./
COPY site/web/src ./src
RUN npm run build
# L'import map est le seul script inline : son empreinte entre dans la CSP.
COPY site/securite.conf /tmp/securite.conf
RUN set -eu; \
    hash="$(cat dist/importmap.sha256)"; \
    case "$hash" in "'sha256-"*"'") ;; *) echo "empreinte d'import map illisible : $hash" >&2; exit 1 ;; esac; \
    sed "s|@IMPORTMAP_SHA256@|$hash|" /tmp/securite.conf > /web/securite.conf; \
    if grep -q '@IMPORTMAP_SHA256@' /web/securite.conf; then exit 1; fi; \
    rm dist/importmap.sha256

# ── Étape 2 : nginx non privilégié ───────────────────────────────────────────
# Image de base officielle amont, conformément à la règle 4 de
# Cloudox/infra/AGENTS.md (« logiciel tiers : image officielle, aucun miroir »).
FROM docker.io/library/nginx:1.27-alpine

# Le namespace applique `pod-security.kubernetes.io/enforce: restricted` :
# le conteneur tourne en UID 10001 avec une racine en lecture seule.
ARG UID=10001
ARG GID=10001

# Source des téléchargements publics : le miroir GitHub, pas la forge.
# La forge exige une connexion même pour un dépôt public (404 anonyme sur
# l'API, la page du dépôt ET les assets — mesuré). Surchargeable par le
# Deployment : la page doit pouvoir suivre un renommage sans reconstruction.
ENV CUBOX_RELEASES_BASE="https://api.github.com" \
    CUBOX_RELEASES_HOST="api.github.com" \
    CUBOX_RELEASES_REPO="yapixgs/Cubox-publique"

# ⚠️ Sans ce filtre, l'entrypoint substitue TOUTES les variables shell du
# template — y compris `$uri` et `$upstream_cache_status`, qui deviendraient
# vides. La configuration serait alors invalide, ou pire : valide et fausse.
# (Le commentaire est volontairement HORS du ENV multi-ligne : selon la version
# du parseur, un `#` au milieu d'une continuation n'est pas toujours retiré.)
# NGINX_LOCAL_RESOLVERS : le serveur DNS du pod, posé par l'entrypoint
# (15-local-resolvers.envsh) quand NGINX_ENTRYPOINT_LOCAL_RESOLVERS est défini ;
# il sert au `resolver` du relais GitHub (résolution dynamique, voir le template).
ENV NGINX_ENVSUBST_FILTER="CUBOX_|NGINX_LOCAL_RESOLVERS" \
    NGINX_ENTRYPOINT_LOCAL_RESOLVERS=1

COPY site/nginx-main.conf         /etc/nginx/nginx.conf
COPY site/default.conf.template   /etc/nginx/templates/default.conf.template
COPY --from=web /web/securite.conf /etc/nginx/securite.conf
COPY --from=web /web/dist/        /usr/share/nginx/html/
COPY HMCL/image/cubox.png         /usr/share/nginx/html/cubox.png
# Le script d'installation Arch est servi par le site : c'est l'adresse qu'on
# donne aux gens, elle doit être stable et indépendante de la dernière release.
COPY packaging/arch/install-arch.sh /usr/share/nginx/html/install-arch.sh

# L'entrypoint officiel écrit le résultat de la substitution dans
# /etc/nginx/conf.d/ : ce dossier doit appartenir à l'utilisateur du conteneur,
# sinon le démarrage échoue en « Permission denied » — en UID 10001 on ne peut
# pas écrire dans un dossier appartenant à root.
RUN chown -R "${UID}:${GID}" /usr/share/nginx/html /etc/nginx/conf.d

USER 10001:10001

# 8080 et pas 80 : un processus non privilégié ne peut pas se lier sous 1024.
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz >/dev/null || exit 1

CMD ["nginx", "-g", "daemon off;"]
