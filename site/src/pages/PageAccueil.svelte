<!-- La page publique de téléchargement : accroche, téléchargements de la dernière version, fonctions, premiers pas. -->
<script>
  import { Badge, Panel, Prompt, Spinner } from '@cloudox/socle'
  import { onMount } from 'svelte'
  import Telechargements from '../lib/Telechargements.svelte'
  import { ADRESSE_VERSIONS, DOC_PACMAN, MIROIR, chargerVersions, notesDesVersions, sectionsDuJournal } from '../lib/versions.js'

  /** @typedef {Awaited<ReturnType<typeof chargerVersions>>} Versions */
  /** @type {{ etat: 'chargement' } | { etat: 'ok', derniere: Versions['derniere'], historique: Versions['historique'] } | { etat: 'erreur', message: string }} */
  let versions = $state({ etat: 'chargement' })

  // Les notes viennent des Releases du miroir (R4.9) ; CHANGELOG.md, embarqué au build,
  // garde celles des versions antérieures à la v1.4.0 et sert si le miroir ne répond pas.
  const ARCHIVE = sectionsDuJournal(__JOURNAL_CUBOX__)
  const NOUVEAUTES = $derived.by(() => notesDesVersions(versions.etat === 'ok' ? versions.historique : null, ARCHIVE))

  onMount(async () => {
    try {
      const trouvees = await chargerVersions()
      versions = { etat: 'ok', derniere: trouvees.derniere, historique: trouvees.historique }
    } catch (echec) {
      console.warn('liste des versions indisponible', echec)
      versions = { etat: 'erreur', message: echec instanceof Error ? echec.message : String(echec) }
    }
  })

  const INSTALL_ARCH = 'curl -fsSLO https://cubox.yabox.wasabout.net/install-arch.sh && bash install-arch.sh'
  // Publiée ICI et pas seulement dans le script : la comparer à une source obtenue autrement
  // est ce qui empêche un serveur compromis de faire passer sa propre clé.
  const EMPREINTE = '6D5D EECF CD53 3845 32D6  1D66 7FC7 6ECD BCCF 57F2'

  const FONCTIONS = [
    { etiquette: 'Mods', titre: 'Mods et modpacks', texte: 'Forge, Fabric, Quilt, NeoForge et OptiFine depuis le launcher. Import Modrinth, CurseForge et MultiMC, navigateur Modrinth intégré.' },
    { etiquette: 'Hors ligne', titre: 'Aucun compte', texte: "Mode hors-ligne par défaut : un pseudo, rien d'autre. L'auto-update est désactivée — Cubox ne téléphone à personne." },
    { etiquette: 'Skins', titre: 'Skins persos', texte: 'Via authlib-injector (Ely.by par exemple), toujours sans compte Microsoft. Entièrement optionnel.' },
    { etiquette: 'Systèmes', titre: 'Windows, Linux, Arch', texte: 'Le même build produit le .exe, le .sh et un paquet pacman. Interface en français.' },
  ]

  const ETAPES = [
    { titre: 'Installer', texte: 'Windows : Installer.exe. Linux : ./install.sh. Arch : pacman -U.' },
    { titre: 'Choisir un pseudo', texte: 'Au premier lancement, un compte hors-ligne suffit. Un mini-guide « Premiers pas » t\'accompagne.' },
    { titre: 'Jouer', texte: 'Solo, LAN, serveurs non-premium et modpacks fonctionnent immédiatement.' },
  ]
</script>

<section class="accroche">
  <Prompt user="visiteur" path="Cubox" command="./cubox --hors-ligne" />
  <p class="version">
    {#if versions.etat === 'chargement'}
      <Badge tone="run"><Spinner label="Chargement de la dernière version" /> Chargement…</Badge>
    {:else if versions.etat === 'ok'}
      <Badge tone="ok">Dernière version : {versions.derniere.version}{versions.derniere.date ? ` — ${versions.derniere.date}` : ''}</Badge>
    {:else}
      <Badge tone="warn">Versions sur GitHub</Badge>
    {/if}
  </p>
  <p class="slogan">Minecraft, <span>sans compte Microsoft</span>.</p>
  <p class="chapeau">
    Launcher Minecraft Java Edition qui tourne <b>hors-ligne</b> : un pseudo suffit, rien n'est envoyé à Microsoft.
    Forge, Fabric, Quilt, NeoForge et OptiFine gérés nativement, et Java&nbsp;21 est déjà dans le paquet — il n'y a
    rien à installer à côté.
  </p>
  <p class="actions">
    <a class="principal" href="#telecharger">Télécharger Cubox</a>
    <a href={ADRESSE_VERSIONS} rel="noopener">Toutes les versions</a>
  </p>
</section>

<section id="telecharger" aria-labelledby="titre-telecharger">
  <h2 id="titre-telecharger"><span>#</span> Télécharger</h2>
  <p class="discret">Décompresse, lance, c'est tout. Java est inclus dans chaque archive.</p>

  {#if versions.etat === 'chargement'}
    <p class="discret"><Spinner label="Chargement des versions" /> Chargement des versions…</p>
  {:else if versions.etat === 'ok'}
    <Telechargements version={versions.derniere} />
  {:else}
    <!-- Jamais de section vide : la raison, et le lien direct vers le miroir. -->
    <div class="encadre erreur" role="alert">
      <b>Liste des versions indisponible</b>
      <p>
        {versions.message} — les téléchargements restent accessibles directement sur GitHub :
        <a href={ADRESSE_VERSIONS} rel="noopener">{ADRESSE_VERSIONS}</a>
      </p>
    </div>
  {/if}

  <div class="arch">
    <Panel title="Arch : mises à jour automatiques" tag="pacman">
      <pre class="commande"><span>$</span> {INSTALL_ARCH}</pre>
      <p>Installe le dépôt pacman signé ; ensuite <code>yay -Syu</code> suffit.</p>
      <p>Le script affichera cette empreinte — <b>vérifie qu'elle correspond</b> :</p>
      <p><code class="empreinte">{EMPREINTE}</code></p>
      <p><a href={DOC_PACMAN} rel="noopener">Détails et installation manuelle</a></p>
    </Panel>
  </div>
</section>

<section id="nouveautes" aria-labelledby="titre-nouveautes">
  <h2 id="titre-nouveautes"><span>#</span> Nouveautés</h2>
  {#each NOUVEAUTES as entree, rang (entree.version)}
    <details class="fiche-version" open={rang === 0}>
      <summary><b>{entree.version}</b>{entree.date ? ` — ${entree.date}` : ''}</summary>
      <div class="notes">
        {#each entree.notes as bloc, position (position)}
          {#if bloc.genre === 'titre'}<h3>{bloc.texte}</h3>
          {:else if bloc.genre === 'element'}<p class="element">{bloc.texte}</p>
          {:else}<p>{bloc.texte}</p>{/if}
        {/each}
      </div>
    </details>
  {/each}
  <p class="discret"><a href="{MIROIR}/blob/main/CHANGELOG.md" rel="noopener">Tout le journal des versions</a></p>
</section>

<section id="fonctions" aria-labelledby="titre-fonctions">
  <h2 id="titre-fonctions"><span>#</span> Ce que fait Cubox</h2>
  <div class="grille">
    {#each FONCTIONS as fonction (fonction.etiquette)}
      <Panel title={fonction.titre} tag={fonction.etiquette}><p class="texte">{fonction.texte}</p></Panel>
    {/each}
  </div>
</section>

<section id="demarrer" aria-labelledby="titre-demarrer">
  <h2 id="titre-demarrer"><span>#</span> Bien démarrer</h2>
  <ol class="grille etapes">
    {#each ETAPES as etape, rang (etape.titre)}
      <li><Panel title={etape.titre} tag={String(rang + 1)}><p class="texte">{etape.texte}</p></Panel></li>
    {/each}
  </ol>

  <div class="encadre alerte">
    <b>Serveurs premium</b>
    <p>
      Les serveurs qui exigent une vérification du compte Microsoft (Hypixel et consorts) <b>refuseront la connexion</b> :
      c'est une protection côté serveur qu'aucun launcher hors-ligne ne peut contourner, ce n'est pas un défaut de Cubox.
      Le solo, le LAN, tes propres serveurs et ceux en <code>online-mode=false</code> marchent parfaitement.
    </p>
  </div>

  <p class="actions">
    <a href="{MIROIR}/blob/main/docs/GUIDE_MINECRAFT_DEBUTANT.md" rel="noopener">Guide débutant</a>
    <a href="{MIROIR}/blob/main/CHANGELOG.md" rel="noopener">Nouveautés</a>
    <a href="{MIROIR}/issues" rel="noopener">Signaler un problème</a>
  </p>
</section>

<style>
  section { display: grid; gap: 14px; scroll-margin-top: 70px; min-width: 0; }
  h2 { font-size: 18px; }
  h2 span { color: var(--cx-accent); }
  p { margin: 0; }
  .discret { color: var(--cx-muted); }
  .accroche { padding: 18px 0 6px; }
  .slogan { font-size: clamp(24px, 4.5vw, 40px); font-weight: 800; color: var(--cx-fg-strong); line-height: 1.2; }
  .slogan span { color: var(--cx-accent); text-shadow: var(--cx-glow); }
  .chapeau { max-width: 72ch; color: var(--cx-fg); }
  .chapeau b { color: var(--cx-fg-strong); }
  .actions { display: flex; flex-wrap: wrap; gap: 10px; }
  .actions a { padding: 7px 14px; border: 1px solid var(--cx-line); border-radius: var(--cx-radius-sm); background: var(--cx-panel-2); }
  .actions a:hover { text-decoration: none; border-color: var(--cx-muted); }
  .actions .principal { background: var(--cx-accent); border-color: var(--cx-accent); color: var(--cx-bg); font-weight: 700; box-shadow: var(--cx-glow); }
  .grille { display: grid; grid-template-columns: repeat(auto-fit, minmax(230px, 1fr)); gap: 14px; }
  .etapes { list-style: none; margin: 0; padding: 0; }
  .texte { color: var(--cx-fg); }
  .arch :global(p) { margin: 6px 0 0; }
  .commande { margin: 0; padding: 10px 12px; background: var(--cx-bg); border: 1px solid var(--cx-line); border-radius: var(--cx-radius-sm); white-space: pre-wrap; overflow-wrap: anywhere; color: var(--cx-fg-strong); font: inherit; }
  .commande span { color: var(--cx-accent); }
  code { font: inherit; color: var(--cx-fg-strong); }
  .empreinte { color: var(--cx-detail); overflow-wrap: anywhere; }
  .encadre { border: 1px solid var(--cx-line); border-left-width: 3px; border-radius: var(--cx-radius-sm); padding: 10px 14px; background: var(--cx-panel); }
  .encadre p { margin-top: 4px; overflow-wrap: anywhere; }
  .encadre.erreur { border-left-color: var(--cx-err); }
  .encadre.erreur b { color: var(--cx-err); }
  .encadre.alerte { border-left-color: var(--cx-warn); }
  .encadre.alerte > b { color: var(--cx-warn); }
  .fiche-version { border: 1px solid var(--cx-line); border-radius: var(--cx-radius-sm); background: var(--cx-panel); padding: 10px 14px; }
  .fiche-version summary { cursor: pointer; color: var(--cx-fg-strong); }
  .notes { display: grid; gap: 4px; margin-top: 8px; max-width: 72ch; }
  .notes h3 { font-size: 15px; margin: 8px 0 2px; color: var(--cx-fg-strong); }
  .notes .element { padding-left: 1.2em; text-indent: -1.2em; }
  .notes p { overflow-wrap: anywhere; }
  .notes .element::before { content: '- '; color: var(--cx-accent); }
</style>
