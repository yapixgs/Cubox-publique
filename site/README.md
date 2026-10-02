# `site/` — la page de téléchargement

Sert <https://cubox.yabox.wasabout.net> : présentation du projet, téléchargement
de la dernière version, et le script d'installation Arch.

```
site/
├── Dockerfile                image OCI : build Node du site, puis nginx non privilégié
├── Dockerfile.dockerignore   contexte limité aux fichiers copiés
├── nginx-main.conf           configuration principale
├── default.conf.template     serveur, relais /api/releases, redirection /arch/
├── securite.conf             en-têtes de sécurité et CSP (empreinte de l'import map posée au build)
├── web/                      page publique — Svelte 5 sur le socle Cloudox
│   ├── src/App.svelte        barre du haut (logo Cubox), page, pied de page
│   ├── src/pages/HomePage.svelte
│   ├── src/lib/releases.js   lecture de /api/releases (plateformes, tailles, SHA256)
│   ├── src/lib/Downloads.svelte, src/lib/TopBar.svelte
│   └── tests/                unitaires (vitest) et e2e (Playwright, bureau + mobile)
└── html/admin/               statistiques de téléchargement (ancienne page statique,
                              protégée par la passerelle) — gardée tant que le hub
                              Cloudox ne l'a pas reprise
```

La page publique n'a **aucune connexion** : pas de `Guard` ni de `Shell` du
socle (le `Shell` charge l'utilisateur via `/oauth2/userinfo`, qui n'existe pas
ici). Elle garde **son propre logo**, `HMCL/image/cubox.png`, et utilise les
blocs et variables `--cx-*` du socle.

En production, Svelte et `@cloudox/socle` ne sont pas embarqués : l'import map
produite par `cloudoxApp()` les charge depuis `/_socle/v1/`, que l'ingress route
vers le socle avant nginx. La CSP autorise ce seul script inline par son
empreinte, calculée au build.

## Développer et tester `web/`

`@cloudox/socle` vient du registre npm privé de la forge (`web/.npmrc`) :

```bash
cd site/web
CLOUDOX_NPM_TOKEN=<jeton read:package> npm ci
npm run dev        # http://127.0.0.1:5181, /api/releases relayé vers l'API GitHub
npm run check      # svelte-check
npm test           # vitest
npm run build      # dist/
npx playwright test   # e2e bureau + mobile, /api/releases simulé
```

En dev, `vite.config.js` sert aussi `/cubox.png` et `/install-arch.sh` depuis
le dépôt, comme l'image.

## Construire l'image

Le contexte de build est la **racine du dépôt**, pas `site/` : le `Dockerfile`
reprend le logo déjà versionné dans `HMCL/image/` plutôt que d'en dupliquer une
copie qui divergerait. BuildKit est requis : le jeton npm est un secret monté
le temps du seul `npm ci`, il n'entre dans aucune couche.

```bash
CLOUDOX_NPM_TOKEN=<jeton> docker build --file site/Dockerfile \
  --secret id=npm_token,env=CLOUDOX_NPM_TOKEN --tag cubox-site .
docker run --rm -p 8080:8080 cubox-site
```

## Trois points non évidents

**Les téléchargements viennent du dépôt public**, pas du dépôt de travail : ce
dernier exige une connexion, un visiteur n'y a pas accès.

**`/api/releases` est relayé par nginx** au lieu d'être appelé directement par
le navigateur. L'API publique est plafonnée à 60 requêtes/heure et par IP ;
avec un cache de 5 minutes, le serveur en émet au plus 12 quel que soit le
nombre de visiteurs, et la page continue de s'afficher si l'API est
indisponible. Effet de bord appréciable : la requête reste en même origine,
donc la politique de sécurité de contenu peut rester stricte.

**`NGINX_ENVSUBST_FILTER=CUBOX_` n'est pas décoratif.** Sans ce filtre,
l'entrypoint remplacerait aussi `$uri` et `$upstream_cache_status` par du vide :
la configuration deviendrait invalide, ou pire, valide et fausse.

## Contraintes du conteneur

L'image tourne en **UID 10001** avec une racine en **lecture seule** :

- port **8080** et non 80 — un processus non privilégié ne peut pas se lier
  sous 1024 ;
- PID, fichiers temporaires et cache dans `/tmp` ;
- `/etc/nginx/conf.d` doit être inscriptible : l'entrypoint y écrit le résultat
  de la substitution des variables.

## Variables d'environnement

| Variable | Défaut | Rôle |
|---|---|---|
| `CUBOX_RELEASES_BASE` | `https://api.github.com` | racine de l'API interrogée |
| `CUBOX_RELEASES_HOST` | `api.github.com` | en-tête `Host` et SNI du relais |
| `CUBOX_RELEASES_REPO` | `yapixgs/Cubox-publique` | dépôt public |

Surchargeables au déploiement : la page doit pouvoir suivre un renommage sans
qu'on reconstruise l'image.
