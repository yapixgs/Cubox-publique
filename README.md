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

> Il n'y a **pas de binaire pré-compilé** pour l'instant : chacun compile Cubox
> chez soi. (Les versions finales seront publiées en *Releases* sur la forge.)

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
> et le `.sh` ne font que trouver le Java du système). Pour un paquet qui n'a
> **besoin de rien**, voir « Publier une version finale » ci-dessous.

## Publier une version finale (paquets « besoin de rien »)

Pour distribuer Cubox à des gens qui **n'ont pas Java** (ex. des potes sous
Windows), on génère des paquets qui **embarquent un JRE Java 21** : l'utilisateur
décompresse et lance, sans rien installer.

```bash
./packaging/make-release.sh          # ou : ./packaging/make-release.sh 1.0
```

Le script compile Cubox, télécharge les JRE Temurin 21 et produit dans `dist/` :

| Paquet | Pour | Utilisation |
|---|---|---|
| `Cubox-<version>-windows-x64.zip`  | Windows (rien à installer) | décompresser → double-clic sur `Cubox.exe` |
| `Cubox-<version>-linux-x64.tar.gz` | Linux (rien à installer)   | décompresser → `./Cubox.sh` |

Il suffit ensuite de **téléverser ces fichiers dans une *Release*** sur la forge.
(Ces paquets ne sont créés **que pour les versions finales** ; au quotidien, on
compile en local — voir la section précédente.)

> Le `.exe` trouve son Java dans le dossier `jre-x64\` placé à côté de lui : tant
> que ce dossier reste avec l'exécutable, aucune installation de Java n'est requise.

## Lancer

```bash
java -jar Cubox-<version>.jar
```

Puis : *Ajouter un compte* → **Hors-ligne** → choisir un pseudo. Aucun compte
Microsoft requis.

---

## À propos / Licence (important)

Cubox est un **fork non-officiel** de
[HMCL (Hello Minecraft! Launcher)](https://github.com/HMCL-dev/HMCL),
distribué sous licence **GNU GPL v3**. Cubox **n'est ni affilié ni approuvé**
par le projet HMCL ni par ses auteurs.

Le code source de Cubox reste sous licence **GPLv3** (voir [`LICENSE`](LICENSE)).
Les avis de copyright d'origine de HMCL sont conservés conformément à la licence.

Crédits : HMCL — huangyuhui (`huanghongxun2008@126.com`) et contributeurs.
