# Cubox — Feuille de route

Launcher Minecraft Linux, fork rebrandé de **HMCL** (GPLv3). Tout est consolidé dans **une seule PR**.

## ✅ Fait
- Rebranding HMCL → **Cubox** (nom, fenêtre, artefacts `Cubox-3.0.*`)
- Auto-update HMCL **désactivé** (les MAJ passent par `yay`/`makepkg`)
- **PKGBUILD** (`packaging/aur/`) : install native Arch via `makepkg -si`
- README FR + GPLv3

## 🎨 Direction artistique (validée, ajustable)
- Fond bleu nuit `#0E1B2E` / `#10243B`, surfaces `#16314F`, texte `#E8F1FB`
- Accent cyan néon `#2FA8F0` (anneau du logo) + ambre/or `#F6A623` (cube)
- Motif: anneau hexagonal du logo comme fil rouge de l'UI
- Logo fourni par Yapix → à décliner en icône (16→512px)

## 🎮 Deux modes (à implémenter — UX par-dessus l'existant HMCL)
- **CuboxFO** (Free Offline) 🔵 cyan — compte hors-ligne, petits serveurs, sans Microsoft. Base: `OfflineAccount` + authlib-injector.
- **CuboxPO** (Payant Online) 🟠 or — compte Microsoft premium, gros serveurs en ligne. Base: `MicrosoftAccount`.
- Écran d'accueil = sélecteur 2 tuiles qui pré-configure le bon compte.

## 🛒 Store de mods intégré (à mettre en avant)
HMCL embarque déjà CurseForge + Modrinth. Cubox met en avant 3 catégories (voir `config/cubox/featured-mods.json`):
1. **Redstone & technique** — Carpet, MiniHUD, Tweakeroo
2. **X-Ray** — Xray Vision+ (⚠️ FO/solo uniquement, bannissable en premium)
3. **Copier-coller de structures** — Litematica, WorldEdit, MaLiLib

## 🖱️ 100 % graphique
Aucune ligne de commande après install. Seule commande: `yay -Syu` / `makepkg -si` pour les MAJ.

## 🔜 Reste à faire (dans cette PR)
1. Base installable (rebrand + PKGBUILD) — prête à merger
2. UX sélecteur 2 modes FO/PO
3. Thème + logo/icône Cubox
4. Mise en avant des 3 catégories de mods dans l'UI du store
5. Skins en mode FO (CustomSkinLoader / serveur de skins) — à cadrer
