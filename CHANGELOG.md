# Journal des versions

Les versions publiées se téléchargent sur <https://cubox.yabox.wasabout.net>.

## 1.3.3

### Corrigé
- **La fenêtre affichait un numéro de version erroné** (`1.3.2.unofficial-…`)
  alors que le paquet installé portait bien `1.3.2`. Deux numéros pour une
  seule version, dont celui que voyait l'utilisateur.

## 1.3.2

### Ajouté
- **Dépôt pacman signé** : `yay -Syu` met Cubox à jour comme n'importe quel
  paquet, sans recompiler. Jusqu'ici le paquet restait figé sans le moindre
  message. Voir [`docs/DEPOT-PACMAN.md`](docs/DEPOT-PACMAN.md).
- **Installation Arch en une commande** :
  `curl -fsSLO …/install-arch.sh && bash install-arch.sh`.
  Le script affiche chaque commande privilégiée avant de la lancer, ne pose
  qu'une question — celle qui engage ta confiance envers la clé de signature —
  et fait le ménage derrière lui, y compris de lui-même.

## 1.3.1

### Corrigé
- Les liens du launcher et du site pointaient vers un dépôt qui exige une
  connexion : ils renvoyaient une erreur à qui n'a pas de compte. Ils mènent
  désormais tous au dépôt public.

### Modifié
- Page de téléchargement raccourcie de moitié, sans rien retirer.

## 1.3

### Ajouté
- **Mini-guide « Premiers pas »** au premier lancement.
- **Modpacks conseillés** et **serveurs recommandés** sur la page d'accueil.
- **Skins hors-ligne** via Ely.by, préconfiguré.
- **Installeurs** Windows et Linux : décompresser, lancer, c'est installé.
  Le mode portable reste possible, les binaires sont toujours dans l'archive.
- **Page de téléchargement** sur <https://cubox.yabox.wasabout.net>.
- **Publication automatisée** : plus de paquets assemblés ni téléversés à la
  main.

### Corrigé
- Le numéro de version des paquets publiés portait un suffixe parasite.

## 1.2

### Ajouté
- Notification automatique des mises à jour de mods disponibles.

## 1.1

### Ajouté
- Nom de la fenêtre, lanceur persistant, installation depuis un lien.

## 1.0

Première version : interface entièrement en français, launcher hors-ligne par
défaut, dossier de données stable (`~/.local/share/cubox`), paquets autonomes
avec Java embarqué.
