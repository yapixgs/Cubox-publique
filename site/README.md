# `site/` — la page publique de Cubox

Sert <https://cubox.yabox.wasabout.net> : présentation du projet et
téléchargement de la dernière version.

```
site/
├── Dockerfile              image OCI (nginx non privilégié)
├── nginx-main.conf         configuration principale
├── default.conf.template   serveur + relais /api/releases
└── html/
    ├── index.html          page publique
    ├── style.css           design system Cubox (repris d'Helipix)
    ├── app.js              remplit la section « Télécharger »
    └── admin/              espace réservé (statistiques)
```

## Construire et essayer

Le contexte de build est la **racine du dépôt**, pas `site/` : le Dockerfile
reprend le logo déjà versionné dans `HMCL/image/` au lieu d'en dupliquer une
copie qui divergerait.

```bash
docker build --file site/Dockerfile --tag cubox-site .
docker run --rm -p 8080:8080 cubox-site
# puis http://localhost:8080
```

## Les trois choses à savoir

### 1. Les téléchargements viennent de GitHub, pas de la forge

La forge exige une connexion même pour un dépôt public : un visiteur reçoit
404 sur l'API, sur la page du dépôt **et** sur les assets. La page lit donc
les releases du miroir `yapixgs/Cubox-publique`.
Détail complet dans [`../docs/PUBLIER-UNE-VERSION.md`](../docs/PUBLIER-UNE-VERSION.md).

### 2. `/api/releases` est relayé par nginx

L'API GitHub envoie bien du CORS, donc un `fetch()` direct marcherait. Le
relais sert à **mutualiser le cache** : l'API anonyme est plafonnée à
60 requêtes/heure et par IP. Avec un cache de 5 minutes, le cluster en émet au
plus 12 par heure, quel que soit le nombre de visiteurs — et la page continue
de s'afficher si GitHub tombe (`proxy_cache_use_stale`).

Effet de bord appréciable : la requête est en même origine, donc la CSP peut
rester à `connect-src 'self'`.

### 3. `NGINX_ENVSUBST_FILTER=CUBOX_` n'est pas décoratif

L'entrypoint de l'image nginx officielle substitue les variables du template.
**Sans ce filtre, il remplacerait aussi `$uri` et `$upstream_cache_status`**
par du vide : la configuration deviendrait invalide, ou pire, valide et
fausse. La CI vérifie d'ailleurs qu'aucune variable `CUBOX_*` ne subsiste dans
la configuration rendue.

## Contraintes du conteneur

Le namespace applique `pod-security.kubernetes.io/enforce: restricted`.
L'image tourne donc en **UID 10001**, avec une racine en **lecture seule** :

- port **8080** et non 80 — un processus non privilégié ne peut pas se lier
  sous 1024 ;
- PID, fichiers temporaires et cache dans `/tmp` ;
- `/etc/nginx/conf.d` doit être inscriptible : c'est là que l'entrypoint écrit
  le résultat de la substitution. Sans ça, le conteneur meurt au démarrage sur
  un `Permission denied`.

Les deux emplacements sont montés en `emptyDir` côté cluster
(`Cloudox/infra` → `tenants/cubox/cubox.yaml`).

## L'espace `/admin`

Statistiques de téléchargement, lues sur la même route relayée
(`download_count` est déjà dans la réponse GitHub — aucun appel ni jeton
supplémentaire).

**L'authentification n'est pas faite dans la page** mais par Traefik en amont,
via oauth2-proxy et le groupe Pocket-ID `Cloudox-Cubox`. Une vérification côté
navigateur ne protégerait rien : il suffirait de couper JavaScript.

## Variables d'environnement

| Variable | Défaut | Rôle |
|---|---|---|
| `CUBOX_RELEASES_BASE` | `https://api.github.com` | racine de l'API interrogée |
| `CUBOX_RELEASES_HOST` | `api.github.com` | en-tête `Host` et SNI du relais |
| `CUBOX_RELEASES_REPO` | `yapixgs/Cubox-publique` | dépôt miroir |

Surchargeables par le Deployment : la page doit pouvoir suivre un renommage
sans qu'on reconstruise l'image.
