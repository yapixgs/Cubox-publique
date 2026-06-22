# Cubox — Fonctionnalités & feuille de route

> Document de pilotage du projet Cubox (fork de HMCL).
> Mis à jour au fil de l'avancement.

## ✅ Déjà présent

**Hérité de HMCL (base solide) :**
- Gestion de **toutes les versions** de Minecraft, installation en 1 clic
- **Mod loaders** : Forge, Fabric, Quilt, NeoForge, OptiFine
- **Import de modpacks** : Modrinth, CurseForge, MultiMC
- **Navigateur de mods Modrinth** (fonctionne sans clé)
- Gestion **automatique de Java**
- **Comptes hors-ligne** (pseudo) + skins via authlib-injector (Ely.by…)
- Gestion des **mondes**, sauvegardes, captures d'écran
- **Multijoueur P2P** (Terracotta) — rangé dans « Avancé »

**Ajouts Cubox :**
- Modes **CuboxFO** (hors-ligne) / **CuboxPO** (en ligne) avec accent de couleur
- **UI 100 % en français**
- **Barre latérale clarifiée** (sous-titres explicatifs + section « Avancé »)
- **Thème / branding** Cubox (logo, accent cyan/ambre)
- **Fix de performance** (ombre désactivée en rendu logiciel)
- **Dossier de données stable** (`~/.local/share/cubox`)
- Le mode pilote le **flux de compte** (pas de fenêtre Microsoft en FO)

## 🧩 À ajouter / manquant

| Fonctionnalité | Intérêt pour débuter | Coût / difficulté |
|---|---|---|
| **Mini-guide « Premiers pas »** au 1er lancement | ⭐⭐⭐ | Faible — à faire |
| **Liste de serveurs recommandés** (non-premium friendly) | ⭐⭐⭐ | Faible/moyen |
| **Skins en hors-ligne** (Ely.by préconfiguré) | ⭐⭐ | Faible |
| **Navigateur CurseForge** (clé API gratuite) | ⭐⭐ | Faible |
| **Préréglages modpacks « conseillés débutant »** | ⭐⭐ | Moyen |
| **Ajout rapide de serveur** depuis l'accueil | ⭐⭐ | Moyen |
| **Login Microsoft (CuboxPO)** — serveurs premium | ⭐ (avancé) | Élevé (carte + formulaire MS) → reporté |

## 🗺️ Feuille de route jusqu'à la v1.0

- **v0.5 — Fondations (FAIT)** : rebrand, modes FO/PO, FR, sidebar, perf, dossier données.
- **v0.6 — Onboarding & confort** : guide « Premiers pas », accueil clarifié, (option) CurseForge.
- **v0.7 — Multijoueur facile** : liste de serveurs non-premium, ajout rapide de serveur, doc « jouer en ligne ».
- **v0.8 — Skins & perso** : skins hors-ligne (Ely.by), réglages de thème.
- **v0.9 — Stabilisation** : tests, finitions, documentation utilisateur.
- **v1.0 — Version stable** : tout ce qui précède, poli et documenté.
  - *Login Microsoft = optionnel*, si tu décides d'investir carte + formulaire Microsoft.

## ❌ Volontairement hors périmètre
- **Contourner l'authentification premium / faire croire qu'on possède le jeu** : techniquement impossible (vérification cryptographique côté serveur Mojang) et contraire aux CGU. Cubox reste un launcher honnête, axé hors-ligne.
