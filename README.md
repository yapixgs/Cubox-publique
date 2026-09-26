# Cubox

**Cubox** est un launcher Minecraft (Java Edition) personnalisé, axé sur la
**confidentialité** et le **support natif des mods**.

- 🧩 **Mods & modpacks** natifs : Forge, Fabric, Quilt, NeoForge, OptiFine,
  ainsi que l'import de modpacks Modrinth / CurseForge / MultiMC.
- 🔒 **Sans Microsoft** : Cubox fonctionne en **mode hors-ligne** (un simple
  pseudo, aucun compte, aucune donnée envoyée à Microsoft). L'auto-update vers
  les serveurs d'origine est **désactivé** : Cubox ne « téléphone » à personne.
- 🎨 Skins persos possibles via **authlib-injector** (ex. Ely.by), toujours
  sans compte Microsoft (optionnel).
- 💻 **Multiplateforme** : un même build produit le `.jar` (Windows/Linux/macOS),
  le `.exe` (Windows) et le `.sh` (Linux). Chacun compile Cubox **lui-même**.

> ⚠️ Le mode hors-ligne permet de rejoindre les serveurs **non-premium**
> (`online-mode=false`) et tes propres serveurs. Les serveurs **premium**
> (Hypixel, etc.) qui exigent une vérification du compte refuseront la
> connexion — c'est une protection côté serveur qu'aucun launcher hors-ligne
> ne peut contourner.

## Build (compilation locale)

> Tu n'as **pas besoin de compiler** : rends-toi sur
> **<https://cubox.yabox.wasabout.net>**, télécharge l'archive de ton système,
> extrais-la et lance l'installeur (`Installer.exe` sous Windows,
> `./install.sh` sous Linux). Java est déjà inclus, il n'y a rien d'autre à
> installer. Sous Arch : `sudo pacman -U cubox-*.pkg.tar.zst`.
>
> Les instructions ci-dessous s'adressent à qui veut compiler lui-même.

**Prérequis** : un **JDK 21** et ~1,5 Go d'espace disque libre.

**Linux / macOS** :

```bash
./gradlew :HMCL:makeExecutables
```

**Windows** (dans `cmd` ou PowerShell, à la racine du dépôt) :

```bat
gradlew.bat :HMCL:makeExecutables
```

Résultat dans `HMCL/build/libs/` :

| Fichier | Pour | Lancer avec |
|---|---|---|
| `Cubox-<version>.jar` | Windows / Linux / macOS | `java -jar Cubox-<version>.jar` |
| `Cubox-<version>.exe` | Windows (natif) | double-clic |
| `Cubox-<version>.sh`  | Linux | `sh Cubox-<version>.sh` |

> ℹ️ Ces 3 fichiers ont **besoin de Java 21 installé** sur la machine (le `.exe`
> et le `.sh` ne font que trouver le Java du système). Les paquets publiés, eux,
> embarquent leur propre JRE.

## Construire les paquets distribuables

```bash
./packaging/make-release.sh          # ou : ./packaging/make-release.sh 1.3
```

Le script compile Cubox, télécharge les JRE Temurin 21 et produit dans `dist/`
des paquets qui **n'ont besoin de rien** sur la machine cible :

| Paquet | Contient | Utilisation |
|---|---|---|
| `Cubox-<version>-windows-x64.zip`  | `Installer.exe` + `Cubox.exe` + `jre-x64\` | décompresser → lancer `Installer.exe` |
| `Cubox-<version>-linux-x64.tar.gz` | `install.sh` + `Cubox.sh` + `jre-x64/`      | décompresser → `./install.sh` |
| `cubox-<version>-*.pkg.tar.zst`    | paquet pacman                                | `sudo pacman -U cubox-*.pkg.tar.zst` |

Les deux premiers restent utilisables **en mode portable** : les binaires sont
dans l'archive, l'installeur n'est qu'une commodité.

- **Windows** — `Installer.exe` (NSIS, compilé sous Linux par `makensis`)
  installe dans `%LOCALAPPDATA%\Programs\Cubox` **sans élévation**, pose les
  raccourcis et l'entrée « Applications et fonctionnalités », et fournit un
  désinstalleur.
- **Linux** — `install.sh` installe **sans sudo** dans
  `~/.local/share/cubox`, conformément à XDG, avec entrée de menu, icône et
  commande `cubox`. `uninstall.sh` **conserve les données** par défaut.
- Le paquet **Arch/pacman** n'est généré que si `makepkg` est présent.

> Sans le paquet `nsis`, le `.zip` Windows est produit **sans** installeur et
> le script le dit bruyamment : une archive silencieusement amputée est
> exactement le genre de régression qu'on ne découvre que chez l'utilisateur.

## Publier une version

**Il n'y a rien à téléverser à la main.** Poser un tag suffit :

```bash
git tag v1.3 && git push origin v1.3
```

La CI construit, vérifie le contenu des archives, publie sur la forge, miroite
vers le dépôt public et **contrôle que le téléchargement anonyme fonctionne**.

👉 Procédure complète : [`docs/PUBLIER-UNE-VERSION.md`](docs/PUBLIER-UNE-VERSION.md)

## Lancer

```bash
java -jar Cubox-<version>.jar
```

Puis : *Ajouter un compte* → **Hors-ligne** → choisir un pseudo. Aucun compte
Microsoft requis.

## Documentation

| Document | Contenu |
|---|---|
| [`docs/GUIDE_MINECRAFT_DEBUTANT.md`](docs/GUIDE_MINECRAFT_DEBUTANT.md) | Pour débuter : solo, LAN, serveurs, mods |
| [`docs/PUBLIER-UNE-VERSION.md`](docs/PUBLIER-UNE-VERSION.md) | Sortir une version, et ce que la CI vérifie |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Fonctionnalités et pistes |
| [`CHANGELOG.md`](CHANGELOG.md) | Journal des versions |
| [`site/README.md`](site/README.md) | La page publique |
| [`AGENTS.md`](AGENTS.md) | Conventions de code |

## Structure du dépôt

| Dossier | Rôle |
|---|---|
| `HMCL/`, `HMCLCore/`, `HMCLBoot/` | le launcher (hérité de HMCL) |
| `packaging/` | paquets distribuables, installeurs, PKGBUILD Arch |
| `site/` | la page <https://cubox.yabox.wasabout.net> |
| `.forgejo/workflows/` | intégration continue (runner Cloudox) |
| `docs/` | documentation |

Le déploiement du site vit dans un autre dépôt :
[`Cloudox/infra`](https://forge.oxitablock.com/Cloudox/infra) → `tenants/cubox/`.

---

## À propos / Licence (important)

Cubox est un **fork non-officiel** de
[HMCL (Hello Minecraft! Launcher)](https://github.com/HMCL-dev/HMCL),
distribué sous licence **GNU GPL v3**. Cubox **n'est ni affilié ni approuvé**
par le projet HMCL ni par ses auteurs.

Le code source de Cubox reste sous licence **GPLv3** (voir [`LICENSE`](LICENSE)).
Les avis de copyright d'origine de HMCL sont conservés conformément à la licence.

Crédits : HMCL — huangyuhui (`huanghongxun2008@126.com`) et contributeurs.
