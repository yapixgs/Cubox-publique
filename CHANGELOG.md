# Journal des versions

Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).
Les versions publiées sont téléchargeables sur
<https://cubox.yabox.wasabout.net>.

## 1.3.2

### Ajouté
- **Dépôt pacman signé** : `yay -Syu` met enfin Cubox à jour. Jusqu'ici le
  paquet n'était sur l'AUR sous aucun nom — yay n'avait donc aucune source à
  interroger et le laissait figé, **sans erreur**, indéfiniment.
  Voir [`docs/DEPOT-PACMAN.md`](docs/DEPOT-PACMAN.md).
  Les paquets et la base sont signés en GPG (`SigLevel = Required`) : pacman
  installe en root, et le HTTPS prouve à qui l'on parle, pas qui a fabriqué le
  paquet. Sans la clé privée, un serveur compromis ne peut rien faire passer.

## 1.3.1

### Corrigé
- **Tous les liens publics pointaient vers la forge**, qui exige une connexion :
  ils renvoyaient donc un 404 à quiconque n'a pas de compte. Le launcher (page
  du projet, signalement de bug, aide plateforme) et le site (code source,
  guide, licence, conditions, feuille de route) pointent désormais vers le
  miroir public <https://github.com/yapixgs/Cubox-publique>.
  Certains de ces liens visaient encore l'ancien chemin `Yapix839/Cubox`,
  déplacé depuis — ils étaient donc morts deux fois.
- **Le code du miroir n'était plus synchronisé** : sa branche `main` datait du
  2 juillet quand la forge en était au 26 septembre. Seuls les binaires étaient
  miroités. `release.yml` pousse maintenant le code et le tag, et **vérifie que
  chaque page de documentation visée par le launcher répond bien 200** — livrer
  un binaire contenant des liens morts ne se rattrape pas sans une nouvelle
  version.

### Modifié
- **Page de téléchargement condensée** : gouttières réduites (jusqu'à 10 rem
  entre deux blocs auparavant), cartes plus compactes, grille de fonctions sur
  quatre colonnes. Même contenu, environ deux fois moins de défilement.
- L'encadré d'avertissement teintait son fond en `rgba(245,179,56,.07)`, ce qui
  rendait un beige sale sur le navy et n'appartenait à aucune couleur de la
  charte. Il reprend la surface habituelle avec un simple liseré ambre.
- Pied de page allégé et aligné sur la palette.

## 1.3

### Ajouté
- **Mini-guide « Premiers pas »** affiché au premier lancement.
- **Modpacks conseillés** et **serveurs recommandés** sur la page d'accueil.
- **Skins hors-ligne** via Ely.by, préconfiguré (`auth.offline.Skin`).
- **Installeurs** : `Installer.exe` (Windows, sans élévation) et `install.sh`
  (Linux, sans sudo, conforme XDG), livrés dans les archives. Le mode portable
  reste possible : les binaires sont toujours dans l'archive.
- **Page publique de téléchargement** sur <https://cubox.yabox.wasabout.net>.
- **Intégration continue** : compilation du launcher à chaque proposition, et
  publication automatique des versions vers la forge **et** le miroir public.

### Corrigé
- La version embarquée dans les paquets construits par la CI portait un
  suffixe `unofficial-<commit>` : `HMCL/build.gradle.kts` dérive le numéro de
  `GITHUB_SHA`, que Forgejo exporte. Les archives portaient le bon nom mais le
  launcher affichait le mauvais numéro.
- `make-release.sh` renvoyait **1 après une construction réussie**. Sa dernière
  ligne était `[ -n "$pkg_built" ] && echo …` : hors d'Arch, `pkg_built` est
  vide, la liste `&&` renvoie 1, et c'est le statut de sortie du script.
  Invisible tant qu'il n'avait tourné que sur Arch.
- Le **paquet pacman** n'était pas construit hors d'Arch : le `PKGBUILD`
  clonait le dépôt *distant*, or la forge exige une connexion — le clone
  échouait sans identifiants. Il construit désormais le dépôt **local**
  (`git+file://`), ce qui règle aussi un problème plus sournois : cloner
  `branch=main` empaquetait l'état de `main` au moment du build, pas le commit
  que l'on publie.
- `update.sh` désactivait explicitement le *credential helper* pour « tirer en
  anonyme ». La forge n'acceptant pas l'anonyme, cela garantissait l'échec au
  lieu de l'éviter.

## 1.2

### Ajouté
- Notification automatique des mises à jour de mods disponibles.
- Script de miroir public vers GitHub (`packaging/publish-github.sh`).

## 1.1

### Ajouté
- Nom de la fenêtre, lanceur persistant, installation depuis un lien.

## 1.0

Première version publiée : rebrand complet, interface 100 % en français,
launcher hors-ligne par défaut, dossier de données stable
(`~/.local/share/cubox`), paquets autonomes avec Java embarqué.
