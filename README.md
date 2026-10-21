<div align="center">
  <img src="HMCL/image/cubox.png" width="120" alt="Cubox">

  # Cubox

  **Lanceur Minecraft Java Edition, hors-ligne, avec les mods.**
</div>

Cubox installe et lance Minecraft avec Forge, Fabric, Quilt, NeoForge ou OptiFine, sans
compte Microsoft : un pseudo suffit. Java 21 est inclus dans chaque paquet, l'interface est
en français.

- **Télécharger** : <https://cubox.yabox.wasabout.net> (Windows, Linux, Arch).
- **Versions** : <https://github.com/yapixgs/Cubox-publique/releases>.
- **Débuter** : [guide Minecraft](docs/GUIDE_MINECRAFT_DEBUTANT.md) ·
  [dépôt pacman](docs/DEPOT-PACMAN.md) · [feuille de route](docs/ROADMAP.md).

> Les serveurs qui exigent un compte Microsoft vérifié (Hypixel et consorts) refusent la
> connexion : aucun lanceur hors-ligne ne peut le contourner. Le solo, le LAN et les
> serveurs en `online-mode=false` fonctionnent normalement.

## Développer

- `just dev` : le site de téléchargement sur <http://127.0.0.1:5181> ;
- `./gradlew :HMCL:makeExecutables` : le lanceur (JDK 21), dans `HMCL/build/libs/` ;
- `just ci` : les contrôles de la CI ; `just paquets 1.2.3` : les paquets distribuables.

La documentation des mainteneurs est dans le
[wiki du dépôt](https://forge.oxitablock.com/Cloudox/Cubox/wiki).

## Licence

Cubox est un **fork non officiel** de
[HMCL (Hello Minecraft! Launcher)](https://github.com/HMCL-dev/HMCL), distribué sous
**GNU GPL v3** (voir [`LICENSE`](LICENSE)). Il n'est ni affilié ni approuvé par le projet
HMCL, ni par Mojang ou Microsoft. Les avis de copyright d'origine sont conservés.
Crédits : HMCL — huangyuhui et contributeurs.
