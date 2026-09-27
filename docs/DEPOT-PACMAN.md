# Mettre Cubox à jour sous Arch

Cubox n'est pas publié sur l'AUR. Sans le dépôt décrit ici, `yay -Syu` ne le
met **pas** à jour : il ne trouve aucune source à interroger, le signale
discrètement dans « Missing AUR Packages », et le paquet reste figé
indéfiniment — sans erreur.

## Installation automatique

```bash
curl -fsSLO https://cubox.yabox.wasabout.net/install-arch.sh
bash install-arch.sh
```

Le script installe la clé de signature, déclare le dépôt et installe Cubox.

- Il **affiche chaque commande privilégiée** avant de la lancer.
- Il ne pose **qu'une question** : faire confiance à la clé de signature — la
  seule décision qui engage quelque chose, puisqu'elle revient à autoriser
  l'installation de logiciels en root.
- Il **fait le ménage** en partant : cache pacman, sauvegarde temporaire,
  restes d'une compilation précédente (en demandant), et lui-même.

Il refuse de s'exécuter sans terminal, donc `curl … | bash` ne fonctionne pas :
un script passé dans un tube s'exécute avant qu'on ait pu le lire.

Pour tout retirer :

```bash
sudo pacman -R cubox
```
puis supprimer la section `[cubox]` de `/etc/pacman.conf`.

## Installation manuelle

**1. Faire confiance à la clé**

```bash
curl -fsSL https://cubox.yabox.wasabout.net/arch/cubox-signing-key.asc \
  | sudo pacman-key --add -
sudo pacman-key --lsign-key 6D5DEECFCD53384532D61D667FC76ECDBCCF57F2
```

**2. Déclarer le dépôt** à la fin de `/etc/pacman.conf`

```ini
[cubox]
SigLevel = Required DatabaseOptional
Server = https://cubox.yabox.wasabout.net/arch
```

**3. Installer**

```bash
sudo pacman -Syu cubox
```

## L'empreinte de la clé

```
6D5D EECF CD53 3845 32D6  1D66 7FC7 6ECD BCCF 57F2
```

Le script d'installation affiche cette empreinte et te demande de la comparer.
**Fais-le.** La clé est servie par le même serveur que les paquets : si ce
serveur était compromis, il servirait *sa* clé et *ses* paquets, et tout
paraîtrait normal. La comparer à une source obtenue autrement — cette page,
par exemple — est la seule chose qui casse ce cercle.

## Pourquoi `SigLevel = Required`

`pacman` installe **en root** : ce qu'il accepte de télécharger, il l'exécute
avec tous les droits.

| | Ce que ça prouve |
|---|---|
| **HTTPS** | qu'on parle au bon serveur, et que rien n'a été modifié en route |
| **Signature** | **qui** a fabriqué le paquet — elle est attachée au fichier et survit à une copie |

HTTPS protège le tuyau, la signature protège le contenu. Sans signature, un
détournement DNS suffit à obtenir un certificat valide et à servir un paquet
modifié sous un HTTPS irréprochable.

Vérifié : un paquet altéré dont la base a été recalculée et resignée avec une
autre clé est refusé.

```
error: cubox: key "…" is unknown
error: database 'cubox' is not valid (invalid or corrupted database (PGP signature))
```

C'est le même réglage que les dépôts officiels d'Arch.

## Sans dépôt

Télécharger le `.pkg.tar.zst` depuis
[les versions publiées](https://github.com/yapixgs/Cubox-publique/releases),
puis `sudo pacman -U`. Les mises à jour seront à refaire à la main.
