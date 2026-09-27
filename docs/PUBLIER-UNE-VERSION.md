# Publier une version

Pour les mainteneurs. Il n'y a **rien à construire ni à téléverser à la main** :
poser un tag suffit.

```bash
# 1. aligner le numéro de version (deux fichiers)
#      config/project.properties   versionRoot=1.3.3
#      packaging/aur/PKGBUILD      pkgver=1.3.3
# 2. fusionner, puis
git tag v1.3.3 && git push origin v1.3.3
```

La chaîne de publication construit, vérifie, publie et **s'arrête net** si
quelque chose ne colle pas.

## Ce qu'elle vérifie

| Contrôle | Ce qu'il empêche |
|---|---|
| tag ↔ `versionRoot` | un tag `v1.3.3` embarquant du code versionné 1.3.2 |
| version inscrite dans le jar | un numéro affiché dans la fenêtre différent du numéro du paquet |
| contenu des archives | une archive sans installeur ou sans Java |
| sommes de contrôle | une archive corrompue |
| **téléchargement anonyme** | publier une version que personne ne peut récupérer |
| pages de documentation | livrer un binaire contenant des liens morts |

Le dernier contrôle télécharge un fichier **sans aucune authentification** :
c'est ce que verra un visiteur. Vérifier en étant authentifié ne prouverait
rien.

## Ce qu'elle produit

```
Cubox-<version>-windows-x64.zip     Installer.exe + Cubox.exe + Java
Cubox-<version>-linux-x64.tar.gz    install.sh + Cubox.sh + Java
cubox-<version>-any.pkg.tar.zst     paquet pacman, signé
Cubox-<version>-SHA256.txt          sommes de contrôle
cubox.db, cubox.files, *.sig        dépôt pacman signé
cubox-signing-key.asc               clé publique de signature
```

Tout est publié sur le dépôt public, d'où le site et `pacman` les récupèrent.

## Secrets nécessaires

| Secret | Sans lui |
|---|---|
| `GH_MIRROR_TOKEN` | la publication échoue — plutôt que de sortir une version invisible |
| `ARCH_SIGNING_KEY` | le dépôt pacman n'est pas publié (un dépôt non signé serait pire que rien) |
| `CURSEFORGE_API_KEY` | seul le navigateur CurseForge est désactivé |

La clé de signature doit être **sans phrase de passe** : une chaîne de
publication automatique ne peut pas en saisir une, et stocker le mot de passe
à côté de la clé ne protégerait plus rien.

## Rejouer une publication

La publication est idempotente : elle réutilise la version existante, remplace
les fichiers de même nom et met le dépôt public à jour. On peut la relancer
sans rien supprimer au préalable.

## Deux pièges à connaître

**Le numéro de version.** `HMCL/build.gradle.kts` dérive le numéro de la
variable `GITHUB_SHA` si elle est définie :

```kotlin
version = if (shortCommit.isNullOrBlank()) versionRoot
          else "$versionRoot.unofficial-$shortCommit"
```

Tout environnement d'intégration continue l'exporte. Chaque build de
publication la retire donc explicitement (`env -u GITHUB_SHA`) — on la retire
plutôt que de la vider, car `"".substring(0, 7)` lève une exception. C'est ce
numéro-là qui s'affiche dans la fenêtre du launcher.

**Le nom du paquet pacman.** L'*epoch* introduit un `:` dans le nom du fichier,
caractère interdit par la plateforme d'hébergement, qui le remplace
silencieusement par un `.`. Or `pacman` télécharge le nom inscrit dans sa base :
les deux divergeraient. Le nom est donc assaini **avant** de construire la base.

## Mettre à jour le site

Le site est déployé séparément et épingle une image précise. **Publier une
version ne le met pas à jour** : il faut y reporter la nouvelle image, sinon la
page servie reste celle d'avant — sans que rien ne soit signalé comme en
erreur.
