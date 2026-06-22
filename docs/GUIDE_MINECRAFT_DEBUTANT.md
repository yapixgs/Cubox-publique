# Minecraft & serveurs — guide pour débuter

> Pour quelqu'un qui a joué au Minecraft de base mais jamais sur des serveurs.

## 1. Solo vs multijoueur
- **Solo** : tu joues sur ton PC, tes mondes sont stockés localement. Rien d'autre à configurer.
- **Multijoueur** : tu te connectes à un **serveur** = un ordinateur qui fait tourner un monde en permanence, accessible à plusieurs joueurs en même temps.

## 2. C'est quoi un serveur ?
Un serveur Minecraft, c'est un programme qui héberge un **monde partagé**. Les joueurs s'y connectent via une **adresse** (une IP comme `51.83.x.x`, ou un nom de domaine comme `mc.exemple.net`). Le serveur gère le monde, les règles et les joueurs connectés.

**Logiciels de serveur courants :**
- **Vanilla** : Minecraft officiel, sans modification.
- **Paper / Spigot / Purpur** : versions optimisées qui acceptent des **plugins** (le plus courant pour les serveurs publics).
- **Forge / Fabric (modded)** : serveurs avec **mods** (il faut alors les **mêmes mods** côté joueur).

**Types d'expérience :** Survie, Minijeux (type Hypixel), Créatif, SkyBlock, Roleplay, Anarchy…

## 3. Premium vs non-premium ⚠️ (le point clé pour toi)
Chaque serveur a un réglage `online-mode` :
- **`online-mode=true` → serveur PREMIUM** : il vérifie ton compte Microsoft auprès de Mojang. Il faut **posséder le jeu + un compte Microsoft**. → ce sera **CuboxPO**, plus tard.
- **`online-mode=false` → serveur NON-PREMIUM** (aussi appelé « offline » / « cracked ») : aucune vérification, tu joues avec un **simple pseudo**. → **CuboxFO fonctionne dessus dès maintenant.**

> Les gros serveurs connus (Hypixel…) sont **premium**. Mais il existe **énormément de serveurs non-premium** auxquels tu peux jouer tout de suite avec Cubox en hors-ligne.

## 4. Comment rejoindre un serveur
1. Lance Minecraft via Cubox (mode **CuboxFO**, choisis un pseudo).
2. Dans le jeu : menu **Multijoueur** → **Ajouter un serveur**.
3. Renseigne l'**adresse** du serveur (IP ou nom de domaine).
4. **Vérifie que ta version de Minecraft = la version du serveur** (ex. 1.20.1). C'est l'erreur n°1 des débutants.
5. Double-clique sur le serveur pour te connecter.

## 5. Héberger ton propre serveur (du plus simple au plus avancé)
1. **Ouvrir à la LAN** : en solo, `Échap` → « Ouvrir à la LAN ». Les gens sur ton réseau local (même WiFi) peuvent rejoindre. Le plus simple pour jouer à 2-3.
2. **Hébergeur gratuit** : ex. **Aternos** (gratuit, s'éteint quand personne ne joue) — idéal pour débuter sans rien installer.
3. **Serveur sur ton PC** : télécharger un serveur Paper/Fabric, le configurer (`server.properties` : port `25565`, `online-mode`, etc.), et **ouvrir le port** sur ta box pour que des gens hors de chez toi se connectent. Plus technique.
4. **Hébergeur payant** : serveur 24/7 sans t'occuper de rien (quelques €/mois).

## 6. Mods & modpacks
- **Mod** : ajoute des fonctionnalités (minimap, machines, etc.). Nécessite un **mod loader** (Fabric, Forge…). Cubox installe le loader pour toi.
- **Modpack** : un ensemble de mods préconfiguré et équilibré. Cubox sait les **importer** (Modrinth / CurseForge).
- **Jouer modded en multi** : le serveur **et** toi devez avoir **exactement les mêmes mods**.

## 7. Par où commencer (le parcours conseillé)
1. **Solo** d'abord : crée un monde, prends tes marques avec Cubox.
2. **LAN ou Aternos** entre potes : ta première expérience multi, sans premium.
3. **Un serveur non-premium** public pour découvrir une communauté.
4. **Un modpack léger** (via Modrinth) pour goûter aux mods.
5. **Plus tard** : premium (CuboxPO) si tu veux les gros serveurs type Hypixel.

## 8. Ce qui marche avec Cubox aujourd'hui
| Tu veux… | Mode | Dispo maintenant ? |
|---|---|---|
| Jouer en solo | CuboxFO | ✅ Oui |
| Jouer en LAN / avec des potes | CuboxFO | ✅ Oui |
| Serveurs **non-premium** | CuboxFO | ✅ Oui |
| Mods & modpacks (Modrinth) | CuboxFO | ✅ Oui |
| Serveurs **premium** (Hypixel…) | CuboxPO | ⏳ Plus tard (compte Microsoft requis) |
