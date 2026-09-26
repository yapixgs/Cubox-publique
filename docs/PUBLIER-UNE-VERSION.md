# Publier une version de Cubox

Tout passe par la CI. Il n'y a **plus rien à construire ni à téléverser à la
main** : la seule action manuelle est de poser un tag.

---

## En une minute

```bash
# 1. Aligner le numéro de version dans le code
#    (config/project.properties ET packaging/aur/PKGBUILD)
# 2. Fusionner cette modification dans main
# 3. Poser le tag
git switch main && git pull
git tag v1.3
git push origin v1.3
```

Le workflow **Release** fait le reste et **s'arrête net** si quelque chose ne
colle pas. Ce n'est pas de la prudence décorative : chaque contrôle correspond
à une erreur qui a réellement pu se produire.

---

## Ce que la CI fait, dans l'ordre

| # | Étape | Ce qu'elle empêche |
|---|---|---|
| 1 | Compare le tag à `versionRoot` | Un tag `v1.3` portant du code versionné 1.2 : les binaires ne veulent plus rien dire |
| 2 | `make-release.sh`, avec `makensis` | — |
| 3 | Vérifie le **contenu** des archives | Une archive sans `Installer.exe` ou sans JRE — la régression que l'utilisateur découvrirait à notre place |
| 4 | `sha256sum -c` | Une archive corrompue |
| 5 | Publie sur la forge | — |
| 6 | Miroite vers GitHub | — |
| 7 | **Télécharge un asset sans authentification** | Publier une version que personne ne peut récupérer |
| 8 | Construit le paquet pacman (`archlinux:base-devel`) | — |

L'étape 7 est la plus importante et la moins évidente. Voir plus bas.

---

## Aligner la version — les deux endroits

```properties
# config/project.properties
versionRoot=1.3
```

```bash
# packaging/aur/PKGBUILD
pkgver=1.3
# et dans la fonction pkgver() :
printf "1.3.r%s.g%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
```

Si `versionRoot` ne correspond pas au tag, la CI refuse de publier — c'est
l'étape 1.

Pensez aussi à `CHANGELOG.md`, qui n'est pas vérifié automatiquement.

---

## ⚠️ Pourquoi les téléchargements passent par GitHub

**La forge exige une connexion, même pour un dépôt marqué public.** Mesuré
depuis un conteneur sans identifiants :

```
/api/v1/version                                      200
/api/v1/repos/Cloudox/Cubox                          404
/api/v1/repos/Cloudox/Cubox/releases                 404
/Cloudox/Cubox                                       404
/Cloudox/Cubox/releases/download/v1.2/…SHA256.txt    404
```

Un visiteur ne peut donc **rien** télécharger depuis la forge. C'est pour ça
que `packaging/publish-github.sh` existait déjà, et pourquoi la CI le
systématise :

- **la forge** est la source de vérité (code, releases, historique) ;
- **`github.com/yapixgs/Cubox-publique`** est le canal de distribution ;
- **cubox.yabox.wasabout.net** lit les releases GitHub et pointe dessus.

L'étape 7 fait un `curl` **sans aucun jeton**, exprès : c'est ce que verra un
visiteur. Vérifier avec un jeton ne prouverait rien — c'est précisément
l'erreur qui aurait laissé croire que la forge suffisait.

---

## Secrets nécessaires

| Secret | Où | Sans lui |
|---|---|---|
| `GH_MIRROR_TOKEN` | Dépôt `Cloudox/Cubox` → Actions → Secrets | La publication **échoue** à l'étape 6, plutôt que de sortir une version invisible |
| `FORGEJO_REGISTRY_USER` / `_TOKEN` | Organisation Cloudox | `images.yml` ne peut pas publier l'image du site |
| `CURSEFORGE_API_KEY` | Dépôt (facultatif) | Seul le navigateur CurseForge est désactivé |

> ⚠️ Le nom d'un secret **ne peut pas commencer par `GITHUB_`** : la forge
> réserve ce préfixe.
> ```
> PUT …/actions/secrets/GITHUB_MIRROR_TOKEN -> 400 « invalid secret name »
> PUT …/actions/secrets/GH_MIRROR_TOKEN     -> 201
> ```

---

## Rejouer une publication

Le workflow est **idempotent** : il réutilise la release existante, remplace
les assets homonymes et met le miroir à jour. On peut donc le relancer à la
main sans supprimer quoi que ce soit :

*Actions → Release — paquets et miroir public → Run workflow*, avec le tag.

---

## Si ça casse

**Les journaux du runner ne sont pas lisibles par l'API de la forge** (aucun
endpoint de logs dans cette version, et les routes web répondent 404 à un
jeton d'API). Le job `site` de `ci.yml` contourne le problème en publiant son
diagnostic **en commentaire de la PR**. Si vous ajoutez un job susceptible
d'échouer de façon opaque, reprenez ce motif : un diagnostic qu'on ne peut pas
lire ne sert à personne.

### Pièges connus du runner

- **`actions/checkout` ne fonctionne pas dans un job avec `container:`.**
  Établi par bissection (13 jobs sonde, 26/09/2026) : sans conteneur il passe ;
  avec conteneur il échoue sur `debian`, `eclipse-temurin` **et**
  `docker:24-cli` — ni l'image ni la libc ne sont en cause ; un `git clone`
  manuel dans le même conteneur passe. Tous les workflows clonent donc à la
  main. Par prudence, `upload-artifact` / `download-artifact` sont évitées
  aussi (mêmes actions JS, risque non mesuré).

- **`env -u GITHUB_SHA` avant `make-release.sh`.** `HMCL/build.gradle.kts`
  dérive la version de `GITHUB_SHA`, que Forgejo exporte :
  ```kotlin
  val shortCommit = System.getenv("GITHUB_SHA")?.lowercase()?.substring(0, 7)
  version = if (shortCommit.isNullOrBlank()) versionRoot
            else "$versionRoot.unofficial-$shortCommit"
  ```
  Sans ce retrait, le launcher **affiche** `1.3.unofficial-a1b2c3d`, alors que
  les archives portent le bon nom. On retire la variable plutôt que de la
  vider : `"".substring(0, 7)` lève une exception.

- **Le job `paquet-arch` est en `continue-on-error`.** `makepkg` refuse de
  tourner en root, d'où l'utilisateur dédié dans le conteneur. Si ce job
  échoue, Windows et Linux sont déjà publiés — mais l'échec reste rouge, et
  les utilisateurs Arch doivent alors passer par l'archive générique.
