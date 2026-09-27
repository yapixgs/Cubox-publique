<div align="center">
  <img src="HMCL/image/cubox.png" width="120" alt="Cubox">

  # Cubox

  **Launcher Minecraft Java Edition, hors-ligne, avec les mods.**

  [Télécharger](https://cubox.yabox.wasabout.net) ·
  [Versions](https://github.com/yapixgs/Cubox-publique/releases) ·
  [Guide débutant](docs/GUIDE_MINECRAFT_DEBUTANT.md) ·
  [Nouveautés](CHANGELOG.md)
</div>

---

- 🧩 **Mods et modpacks** — Forge, Fabric, Quilt, NeoForge, OptiFine. Import
  Modrinth, CurseForge et MultiMC, navigateur Modrinth intégré.
- 🔒 **Aucun compte** — mode hors-ligne : un pseudo suffit, rien n'est envoyé à
  Microsoft. L'auto-update est désactivée.
- 🎨 **Skins persos** — via `authlib-injector` (Ely.by par exemple), toujours
  sans compte Microsoft.
- 💻 **Windows, Linux, Arch** — Java 21 inclus dans chaque paquet, rien d'autre
  à installer. Interface en français.

> ⚠️ Les serveurs qui exigent une vérification du compte Microsoft (Hypixel et
> consorts) refuseront la connexion. C'est une protection côté serveur qu'aucun
> launcher hors-ligne ne peut contourner. Le solo, le LAN, tes propres serveurs
> et ceux en `online-mode=false` fonctionnent normalement.

## Installer

Rends-toi sur **<https://cubox.yabox.wasabout.net>**.

| | |
|---|---|
| **Windows** | décompresser le `.zip`, lancer `Installer.exe` |
| **Linux** | décompresser le `.tar.gz`, lancer `./install.sh` |
| **Arch** | `curl -fsSLO https://cubox.yabox.wasabout.net/install-arch.sh && bash install-arch.sh` |

Sous Arch, le script met en place un dépôt pacman signé : `yay -Syu` met
ensuite Cubox à jour comme n'importe quel paquet.
Voir [`docs/DEPOT-PACMAN.md`](docs/DEPOT-PACMAN.md).

Les installeurs ne demandent aucun privilège d'administrateur : tout va dans
ton dossier personnel, et un désinstalleur est fourni.

## Compiler soi-même

**Prérequis** : JDK 21 et environ 1,5 Go d'espace disque.

```bash
./gradlew :HMCL:makeExecutables
```

Résultat dans `HMCL/build/libs/` : `Cubox-<version>.jar`, `.exe` et `.sh`.
Ces trois fichiers ont besoin d'un Java 21 installé sur la machine.

Pour produire les paquets distribuables, qui embarquent leur propre Java :

```bash
./packaging/make-release.sh
```

## Structure

| Dossier | Contenu |
|---|---|
| `HMCL/`, `HMCLCore/`, `HMCLBoot/` | le launcher |
| `packaging/` | paquets distribuables, installeurs, `PKGBUILD` Arch |
| `site/` | la page de téléchargement |
| `docs/` | documentation |

## Documentation

| | |
|---|---|
| [Guide Minecraft débutant](docs/GUIDE_MINECRAFT_DEBUTANT.md) | solo, LAN, serveurs, mods |
| [Dépôt pacman](docs/DEPOT-PACMAN.md) | mises à jour automatiques sous Arch |
| [Publier une version](docs/PUBLIER-UNE-VERSION.md) | pour les mainteneurs |
| [Feuille de route](docs/ROADMAP.md) | fonctionnalités et pistes |
| [Journal des versions](CHANGELOG.md) | ce qui change à chaque version |
| [Conventions de code](AGENTS.md) | nullabilité, immuabilité, documentation |

## Licence

Cubox est un **fork non-officiel** de
[HMCL (Hello Minecraft! Launcher)](https://github.com/HMCL-dev/HMCL), distribué
sous **GNU GPL v3** (voir [`LICENSE`](LICENSE)). Cubox n'est ni affilié ni
approuvé par le projet HMCL, ni par Mojang ou Microsoft.

Les avis de copyright d'origine sont conservés conformément à la licence.
Crédits : HMCL — huangyuhui et contributeurs.
