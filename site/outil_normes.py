"""L'outil `normes`, avec le site de Cubox déclaré comme unité (dérogation R3.2).

Le référentiel ne connaît que les composants `backend` et `frontend` et nomme leurs images
`<produit>-<composant>`. Cubox n'a ni l'un ni l'autre : son site vit dans `site/` et son
image, épinglée dans infra, s'appelle `cloudox/cubox-site` (contrat externe). Ce script
lance les tâches canoniques telles quelles (qualite, tests, e2e, construction, images,
deployer) en ne changeant que ces deux réponses.

Usage : <python de normes> site/outil_normes.py tache construction
"""

from pathlib import Path

from normes import commande, taches
from normes.depot import Depot

IMAGE_DU_SITE = f"{taches.REGISTRE}/cubox-site"


def dossiers_des_unites(depot: Depot) -> list[Path]:
    return [depot.racine / "site"]


def nom_image(depot: Depot, unite: taches.Unite) -> str:
    return IMAGE_DU_SITE


taches.dossiers_des_unites = dossiers_des_unites
taches.nom_image = nom_image

if __name__ == "__main__":
    commande.principal()
