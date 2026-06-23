# Litematica — guide complet (copier-coller de constructions)

> Pour copier une construction et la recoller ailleurs. Litematica est un mod
> **Fabric** : il faut **Fabric** + **Fabric API** + **MaLiLib** + **Litematica**,
> tous pour la **même version** de Minecraft.
>
> Touche du menu : **M** par défaut (**?** sur clavier AZERTY).

## 🔄 Récap : copier → coller

1. **Outil** : tiens un **bâton** en main. Règle le mode : menu → bouton du bas
   **« Tool Mode: Area Selection »** (clique pour faire défiler les modes).
   Laisse **« Area Selection Mode: Simple »**.
2. **Sélectionner** : avec le bâton, **clic gauche** = coin 1, **clic droit** =
   coin opposé → une **boîte colorée** entoure la construction.
   (Englobe TOUT : devant, derrière, et sous le sol si redstone cachée.)
3. **Sauvegarder** : menu → **« Area Editor »** → **« Save Schematic »** →
   tape un nom → **« Save Schematic »**. Message vert = sauvegardé.
4. **Charger** : menu → **« Load Schematics »** → choisis ton schematic →
   **« Load »** → un **hologramme** translucide apparaît.
5. **Coller** (créatif uniquement) :
   - Définis une fois la touche : menu → **Configuration menu** → **Hotkeys** →
     cherche **`executeOperation`** → assigne une touche libre.
   - Règle **« Tool Mode: Paste Schematic in World »**.
   - Vise l'hologramme, appuie sur ta touche → les vrais blocs apparaissent.

## 🧹 Effacer les contours / « trucs de couleur »

Deux types de contours :
- **Boîte de sélection** (copie) → menu → **« Area Selection browser »** →
  supprime la sélection (croix ❌) ou désélectionne-la.
- **Hologramme + sa boîte** (chargement) → menu → **« Load Schematics »** →
  sélectionne → **« Unload »** (retire l'hologramme et son contour).
- 💡 **Tout masquer d'un coup** (sans supprimer) : assigne la touche
  **`toggleAllRendering`** (Configuration → Hotkeys) → un appui cache/affiche
  tous les overlays Litematica.

## 📦 Déplacer / supprimer un hologramme (placement)

Menu → **« Schematic Placements »** → clique le placement :
- **Déplacer** : **« Move to player »** (l'amène à toi), ou règle l'**origine**
  (X/Y/Z), + boutons **rotation / miroir**.
- **Supprimer** : croix **❌ / Remove** (retire l'hologramme, pas le fichier).

## 🗑️ Supprimer un schematic (le fichier `.litematic`)

Menu → **« Schematic Manager »** → **clic droit** sur le fichier → **Delete**
(le menu contextuel permet aussi **Rename** / copier).

## 📤📥 Exporter / importer

Les schematics sont des fichiers **`.litematic`** dans le dossier **`schematics`**
de l'instance (Cubox → instance → **Explorer**).
- **Exporter / partager** : récupère le `.litematic` et envoie-le.
- **Importer** : place un `.litematic` (ou `.schem`, `.nbt`) dans le dossier
  `schematics`, puis menu → **« Load Schematics »** → charge-le.

## 🆘 Si la touche ne fait rien
- Vérifie que tu vois le **HUD en bas à gauche** (sinon l'outil est désactivé →
  **M+T** pour le réactiver).
- Vérifie que tu tiens bien le **bâton** et que tu es en **Créatif** pour coller.

Réf. officielle : https://github.com/maruohon/litematica/wiki
