# Journal des versions

Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/).
Les versions publiées sont téléchargeables sur
<https://cubox.yabox.wasabout.net>.

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
