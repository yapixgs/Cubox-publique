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
- 🐧 Build **Linux** (`.jar` exécutable + script `.sh` autonome).

> ⚠️ Le mode hors-ligne permet de rejoindre les serveurs **non-premium**
> (`online-mode=false`) et tes propres serveurs. Les serveurs **premium**
> (Hypixel, etc.) qui exigent une vérification du compte refuseront la
> connexion — c'est une protection côté serveur qu'aucun launcher hors-ligne
> ne peut contourner.

## Build

Le build se fait automatiquement sur la forge (Forgejo Actions,
`.forgejo/workflows/build.yml`) à chaque push/PR sur `main`. Les artefacts
Linux (`Cubox-<version>.jar` et `Cubox-<version>.sh`) sont publiés dans la
page **Actions** du dépôt.

Build local (nécessite un JDK 21 et ~1,5 Go d'espace disque) :

```bash
./gradlew :HMCL:makeExecutables
# -> HMCL/build/libs/Cubox-<version>.jar  (lancer avec : java -jar Cubox-<version>.jar)
# -> HMCL/build/libs/Cubox-<version>.sh   (lancer avec : sh Cubox-<version>.sh)
```

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
