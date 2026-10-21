# `site/` — la page de téléchargement

Sert <https://cubox.yabox.wasabout.net> : présentation, téléchargement de la dernière
version (lue sur le miroir public GitHub), script d'installation Arch. Svelte 5 sur le
socle Cloudox, servi par nginx non privilégié (image `cloudox/cubox-site`).

```bash
just dev          # http://127.0.0.1:5181, /api/releases relayé vers l'API GitHub
just qualite      # svelte-check (et le reste du dépôt)
just tests        # vitest (et les tests du lanceur)
just e2e          # Playwright bureau + mobile, /api/releases simulé
just dev-image    # l'image telle qu'en production, sur http://127.0.0.1:8080
```

`@cloudox/socle` vient du registre npm privé de la forge : exporter `CLOUDOX_NPM_TOKEN`
(jeton `read:package`) avant `npm ci`.

Fonctionnement, variables d'environnement et pièges : wiki du dépôt, page
`Explication-Site`.
