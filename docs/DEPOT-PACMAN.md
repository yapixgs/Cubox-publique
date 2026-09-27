# Mettre Cubox à jour avec pacman

Par défaut, **`yay -Syu` ne met pas Cubox à jour**. Le paquet n'est publié sur
l'AUR sous aucun nom : yay interroge l'AUR pour chaque paquet étranger et
n'obtient rien.

```
$ curl 'https://aur.archlinux.org/rpc/v5/info?arg[]=cubox'
{"resultcount":0,"results":[]}
```

Il le signale dans « Missing AUR Packages » et passe à côté. Le paquet reste
installé et figé, **sans erreur**, indéfiniment.

Le dépôt pacman ci-dessous corrige ça.

---

## Installation — une seule fois

**1. Faire confiance à la clé qui signe les paquets**

```bash
curl -fsSL https://cubox.yabox.wasabout.net/arch/cubox-signing-key.asc \
  | sudo pacman-key --add -
sudo pacman-key --lsign-key <EMPREINTE>
```

L'empreinte est affichée dans le récapitulatif de chaque publication, et dans
la clé elle-même (`gpg --show-keys cubox-signing-key.asc`).

**2. Déclarer le dépôt** dans `/etc/pacman.conf`, à la fin du fichier :

```ini
[cubox]
SigLevel = Required DatabaseOptional
Server = https://cubox.yabox.wasabout.net/arch
```

**3. Synchroniser**

```bash
sudo pacman -Syu
```

Ensuite, `yay -Syu` ou `pacman -Syu` met Cubox à jour comme n'importe quel
paquet — **sans recompiler**, en téléchargeant le binaire déjà construit.

---

## Pourquoi `SigLevel = Required`

`pacman` installe **en root** : ce qu'il accepte de télécharger, il l'exécute
avec tous les droits. Deux protections différentes entrent en jeu.

| | Ce que ça prouve |
|---|---|
| **HTTPS** | qu'on parle bien au bon serveur, et que rien n'a été modifié *en route* |
| **Signature GPG** | **qui** a fabriqué le paquet — la signature est attachée au fichier, elle survit à une copie ou à un miroir |

Autrement dit : **HTTPS protège le tuyau, la signature protège le contenu.**

Sans signature, quelqu'un qui prend la main sur le serveur — ou qui détourne le
DNS assez longtemps pour obtenir un certificat Let's Encrypt valide — sert un
paquet vérolé sous un HTTPS parfaitement vert, et `pacman` l'installe en root.

### Ce n'est pas une inquiétude théorique : c'est mesuré

Scénario rejoué dans un conteneur Arch — l'attaquant contrôle le serveur, donc
il modifie le paquet **et** recalcule la base (la somme de contrôle concorde),
puis signe avec **sa** clé. La seule chose qu'il n'a pas, c'est la clé légitime :

```
error: cubox: key "93E3FCFA…" is unknown
error: database 'cubox' is not valid (invalid or corrupted database (PGP signature))
>>> pacman a REFUSÉ
```

Une altération à taille constante, avec la base d'origine, est également
refusée (somme de contrôle). Et le cas nominal s'installe normalement.

C'est exactement pour cette raison que les dépôts officiels d'Arch sont en
`SigLevel = Required DatabaseOptional`.

---

## Comment c'est fabriqué

À chaque publication, la CI :

1. construit le paquet (`makepkg`) ;
2. **renomme** le fichier pour remplacer le `:` de l'epoch par un `-`. GitHub
   refuse le `:` dans un nom d'asset et le remplace silencieusement ; comme
   `pacman` télécharge le nom inscrit dans la base, les deux divergeraient et
   il demanderait un fichier inexistant ;
3. signe le paquet, puis construit et signe la base (`repo-add -s`) ;
4. téléverse le tout dans les assets de la release.

`https://cubox.yabox.wasabout.net/arch/…` redirige vers
`…/releases/latest/download/…`. Le dépôt voyage donc avec la version qu'il
décrit : aucun volume à gérer, aucun service supplémentaire, et il se met à
jour tout seul à chaque publication.

Si le secret `ARCH_SIGNING_KEY` est absent, la CI **ne publie pas** de dépôt et
le dit. Publier un dépôt non signé serait pire que pas de dépôt du tout.

---

## Alternative sans dépôt

```bash
cd /chemin/vers/Cubox && ./update.sh   # git pull + makepkg -sif, recompile
```

ou télécharger le `.pkg.tar.zst` depuis
[les releases](https://github.com/yapixgs/Cubox-publique/releases) et
`sudo pacman -U`.
