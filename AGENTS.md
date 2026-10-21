# Agents

Lire le [référentiel d'ingénierie Cloudox](https://forge.oxitablock.com/Cloudox/normes/wiki/Home)
avant d'agir : toutes ses règles s'appliquent ici, sauf les dérogations de `cloudox.toml`.

Propre à ce dépôt :
- **Fork de HMCL.** Le code amont garde ses noms, commentaires et messages (dérogation
  R4.2) ; seul le code propre à Cubox est en français. Ne pas réécrire le code amont sans
  raison : chaque écart complique la reprise des correctifs de HMCL.
- **Contrats publiés, à ne jamais renommer** : l'image `cloudox/cubox-site`, les variables
  `CUBOX_RELEASES_*` du site, la route `/api/releases`, l'adresse `/install-arch.sh`, les
  noms des paquets (`Cubox-<version>-windows-x64.zip`…), le dépôt pacman `cubox`, les
  fichiers publics lus sur le miroir (`README.md`, `CHANGELOG.md`, `LICENSE`, `docs/*.md`),
  les clés de configuration du lanceur et ses fichiers de langue.
- **Distribution** : la forge exige une connexion ; chaque version part aussi sur le miroir
  public GitHub (ADR-0041 d'infra), par le workflow `miroir.yml`. Voir le wiki,
  page `Exploitation-Publier-une-version`.
- **Version** : jamais écrite dans un fichier ; la livraison l'injecte (`VERSION_ROOT`).
- **Java** : JDK 21. Tout nouveau code Java est annoté `@NotNullByDefault`, `@Nullable` et
  `@Unmodifiable` (JetBrains Annotations), et documenté en commentaires `///`.
