# Cubox — Fonctionnalités & feuille de route

> 🏁 **Cubox 1.0 — version finale.** Le projet est livré et **clôturé** à la 1.0.
> Les éléments listés sous « Pistes futures » ne sont **pas inclus** dans la 1.0
> (idées conservées si le projet venait à reprendre).

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

## 🧩 Pistes futures (non incluses en 1.0)

> Idées conservées pour une éventuelle reprise — **pas prévues** dans la version finale.

| Fonctionnalité | Intérêt pour débuter | Coût / difficulté |
|---|---|---|
| **Mini-guide « Premiers pas »** au 1er lancement | ⭐⭐⭐ | Faible — à faire |
| **Liste de serveurs recommandés** (non-premium friendly) | ⭐⭐⭐ | Faible/moyen |
| **Skins en hors-ligne** (Ely.by préconfiguré) | ⭐⭐ | Faible |
| **Navigateur CurseForge** (clé API gratuite) | ⭐⭐ | Faible |
| **Préréglages modpacks « conseillés débutant »** | ⭐⭐ | Moyen |
| **Ajout rapide de serveur** depuis l'accueil | ⭐⭐ | Moyen |
| ~~**Login Microsoft (CuboxPO)** — serveurs premium~~ | ⭐ (avancé) | **Archivé** (carte + formulaire MS impraticables ; nécessite de posséder le jeu) |

## 🏁 Statut : 1.0 — version finale (projet clôturé)

Cubox **1.0** est la version finale livrée :
- rebrand complet, UI 100 % FR, **logo rond**
- **launcher hors-ligne** (mode en ligne « CuboxPO » archivé)
- barre latérale clarifiée, fix de performance, dossier de données stable
- **build local** Linux + Windows, et **paquets autonomes** (Java embarqué) pour la distribution
- dépôt nettoyé, version affichée **« Cubox v1.0 »**

> *Mode en ligne (CuboxPO) = archivé*, réactivable plus tard si besoin
> (carte + formulaire Microsoft + posséder le jeu).

## ❌ Volontairement hors périmètre
- **Contourner l'authentification premium / faire croire qu'on possède le jeu** : techniquement impossible (vérification cryptographique côté serveur Mojang) et contraire aux CGU. Cubox reste un launcher honnête, axé hors-ligne.
