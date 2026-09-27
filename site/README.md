# `site/` — la page de téléchargement

Sert <https://cubox.yabox.wasabout.net> : présentation du projet, téléchargement
de la dernière version, et le script d'installation Arch.

```
site/
├── Dockerfile              image OCI (nginx non privilégié)
├── nginx-main.conf         configuration principale
├── default.conf.template   serveur, relais /api/releases, redirection /arch/
└── html/
    ├── index.html          page publique
    ├── style.css           design system
    ├── app.js              remplit la section « Télécharger »
    └── admin/              espace réservé (statistiques)
```

## Essayer en local

Le contexte de build est la **racine du dépôt**, pas `site/` : le `Dockerfile`
reprend le logo déjà versionné dans `HMCL/image/` plutôt que d'en dupliquer une
copie qui divergerait.

```bash
docker build --file site/Dockerfile --tag cubox-site .
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
