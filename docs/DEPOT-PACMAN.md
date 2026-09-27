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

## Installation automatique (recommandé)

```bash
curl -fsSLO https://cubox.yabox.wasabout.net/install-arch.sh
bash install-arch.sh
```

Le script installe la clé, déclare le dépôt et installe Cubox. Il **affiche
chaque commande privilégiée** avant de la lancer, et ne pose **qu'une seule
question** : celle qui engage vraiment quelque chose — faire confiance à la
clé de signature, ce qui revient à autoriser l'installation de logiciels en
root sur ta machine.

Le reste (télécharger un fichier, ajouter une ligne à `pacman.conf`, lancer
`pacman -S`) sont les gestes ordinaires d'une installation. Multiplier les
« continuer ? » n'ajoute aucune sécurité : ça apprend à taper « o » sans lire,
y compris le jour où la question compte.

> Il refuse de tourner sans terminal — donc `curl … | bash` ne marche pas, et
> c'est voulu : un script passé dans un tube s'exécute avant que tu aies pu le
> lire. Télécharge-le, ouvre-le, puis lance-le.

### Il fait le ménage derrière lui

Une installation qui laisse traîner ses outils n'est pas terminée. À la fin, le
script retire :

- le paquet téléchargé dans le cache de pacman (re-téléchargeable à tout moment) ;
- la sauvegarde de `pacman.conf` — **seulement après** avoir vérifié que pacman
  fonctionne toujours, puisque c'est précisément ce qu'elle servait à garantir ;
- les restes d'une compilation précédente (`src/`, `pkg/`, `*.pkg.tar.zst`) s'il
  en trouve — **en demandant**, parce que ce sont tes dossiers, pas les siens ;
- **et lui-même**. Le laisser traîner, c'est inviter à le relancer un jour avec
  une empreinte périmée.

Il ne reste que le logiciel et le dépôt qui le met à jour.

Dernière vérification avant de partir, il contrôle que Cubox n'est plus un
paquet *étranger* :

```
✔ cubox vient bien du dépôt [cubox] — yay -Syu le suivra
```

C'est exactement ce qui manquait avant : tant que `pacman -Qm` listait `cubox`,
yay le cherchait sur l'AUR — où il n'existe pas — et le laissait figé sans rien
dire.

Tout retirer : `sudo pacman -R cubox`, puis retirer la section `[cubox]` de
`/etc/pacman.conf`.

---

## Installation manuelle — une seule fois

**1. Faire confiance à la clé qui signe les paquets**

```bash
curl -fsSL https://cubox.yabox.wasabout.net/arch/cubox-signing-key.asc \
  | sudo pacman-key --add -
sudo pacman-key --lsign-key 6D5DEECFCD53384532D61D667FC76ECDBCCF57F2
```

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

## L'empreinte de la clé

```
6D5D EECF CD53 3845 32D6  1D66 7FC7 6ECD BCCF 57F2
```

**Compare-la** à celle que le script d'installation t'affiche. Ce contrôle
n'est pas une formalité : la clé est servie par le même serveur que les
paquets. Si ce serveur était compromis, il servirait *sa* clé et *ses*
paquets, et tout paraîtrait normal. La comparer à une source obtenue
autrement — cette page sur GitHub, par exemple — est la seule chose qui casse
ce cercle.

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
