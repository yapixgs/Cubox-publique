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
- **Launcher hors-ligne** (le mode en ligne « CuboxPO » est **archivé/hiberné** — voir `setting.Cubox.OFFLINE_ONLY`)
- **UI 100 % en français**
- **Barre latérale clarifiée** (sous-titres explicatifs + section « Avancé »)
- **Thème / branding** Cubox (logo **rond**, accent cyan)
- **Fix de performance** (ombre désactivée en rendu logiciel)
- **Dossier de données stable** (`~/.local/share/cubox`)
- Flux de compte **hors-ligne par défaut**, option Microsoft masquée
- **Dépôt nettoyé** : restes HMCL retirés (docs traduites, config Jenkins) ;
  doc de référence réduite à `README.md` + ce fichier + le guide débutant

## 🧩 À ajouter / manquant

| Fonctionnalité | Intérêt pour débuter | Coût / difficulté |
|---|---|---|
| **Mini-guide « Premiers pas »** au 1er lancement | ⭐⭐⭐ | Faible — à faire |
| **Liste de serveurs recommandés** (non-premium friendly) | ⭐⭐⭐ | Faible/moyen |
| **Skins en hors-ligne** (Ely.by préconfiguré) | ⭐⭐ | Faible |
| **Navigateur CurseForge** (clé API gratuite) | ⭐⭐ | Faible |
| **Préréglages modpacks « conseillés débutant »** | ⭐⭐ | Moyen |
| **Ajout rapide de serveur** depuis l'accueil | ⭐⭐ | Moyen |
| ~~**Login Microsoft (CuboxPO)** — serveurs premium~~ | ⭐ (avancé) | **Archivé** (carte + formulaire MS impraticables ; nécessite de posséder le jeu) |

## 🗺️ Feuille de route jusqu'à la v1.0

- **v0.5 — Fondations (FAIT)** : rebrand, FR, sidebar, perf, dossier données, **passage en launcher hors-ligne** (CuboxPO archivé), **logo rond + nettoyage du dépôt**.
- **v0.6 — Onboarding & confort** : guide « Premiers pas », accueil clarifié, (option) CurseForge.
- **v0.7 — Multijoueur facile** : liste de serveurs non-premium, ajout rapide de serveur, doc « jouer en ligne ».
- **v0.8 — Skins & perso** : skins hors-ligne (Ely.by), réglages de thème.
- **v0.9 — Stabilisation** : tests, finitions, documentation utilisateur.
- **v1.0 — Version stable** : tout ce qui précède, poli et documenté. Cubox = launcher hors-ligne complet.
  - *Mode en ligne (CuboxPO) = archivé*, réactivable plus tard si besoin (carte + formulaire Microsoft + posséder le jeu).

## ❌ Volontairement hors périmètre
- **Contourner l'authentification premium / faire croire qu'on possède le jeu** : techniquement impossible (vérification cryptographique côté serveur Mojang) et contraire aux CGU. Cubox reste un launcher honnête, axé hors-ligne.
