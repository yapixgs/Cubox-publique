<!-- The public download page: hero, downloads of the latest release, features, getting started. -->
<script>
  import { Badge, Panel, Prompt, Spinner } from '@cloudox/socle'
  import { onMount } from 'svelte'
  import Downloads from '../lib/Downloads.svelte'
  import { MIRROR, PACMAN_DOC, RELEASES_URL, changelogSections, fetchReleases } from '../lib/releases.js'

  /** @type {{ state: 'loading' } | { state: 'ok', release: Awaited<ReturnType<typeof fetchReleases>>['latest'], history: Awaited<ReturnType<typeof fetchReleases>>['history'] } | { state: 'error', message: string }} */
  let releases = $state({ state: 'loading' })

  // The notes are the CHANGELOG of the repository, embedded at build time; the date
  // comes from the published release when the mirror answers.
  const CHANGES = changelogSections(__CUBOX_CHANGELOG__)
  /** @param {string} version */
  const dateOf = (version) =>
    releases.state === 'ok' ? releases.history.find((entry) => entry.version.replace(/^v/, '') === version)?.date ?? '' : ''

  onMount(async () => {
    try {
      const found = await fetchReleases()
      releases = { state: 'ok', release: found.latest, history: found.history }
    } catch (error) {
      console.warn('liste des versions indisponible', error)
      releases = { state: 'error', message: error instanceof Error ? error.message : String(error) }
    }
  })

  const INSTALL_ARCH = 'curl -fsSLO https://cubox.yabox.wasabout.net/install-arch.sh && bash install-arch.sh'
  // Published HERE and not only in the script: comparing it with a source obtained another way
  // is what stops a compromised server from passing its own key.
  const FINGERPRINT = '6D5D EECF CD53 3845 32D6  1D66 7FC7 6ECD BCCF 57F2'

  const FEATURES = [
    { tag: 'Mods', title: 'Mods et modpacks', text: 'Forge, Fabric, Quilt, NeoForge et OptiFine depuis le launcher. Import Modrinth, CurseForge et MultiMC, navigateur Modrinth intégré.' },
    { tag: 'Hors ligne', title: 'Aucun compte', text: "Mode hors-ligne par défaut : un pseudo, rien d'autre. L'auto-update est désactivée — Cubox ne téléphone à personne." },
    { tag: 'Skins', title: 'Skins persos', text: 'Via authlib-injector (Ely.by par exemple), toujours sans compte Microsoft. Entièrement optionnel.' },
    { tag: 'Systèmes', title: 'Windows, Linux, Arch', text: 'Le même build produit le .exe, le .sh et un paquet pacman. Interface en français.' },
  ]

  const STEPS = [
    { title: 'Installer', text: 'Windows : Installer.exe. Linux : ./install.sh. Arch : pacman -U.' },
    { title: 'Choisir un pseudo', text: 'Au premier lancement, un compte hors-ligne suffit. Un mini-guide « Premiers pas » t\'accompagne.' },
    { title: 'Jouer', text: 'Solo, LAN, serveurs non-premium et modpacks fonctionnent immédiatement.' },
  ]
</script>

<section class="hero">
  <Prompt user="visiteur" path="Cubox" command="./cubox --hors-ligne" />
  <p class="version">
    {#if releases.state === 'loading'}
      <Badge tone="run"><Spinner label="Chargement de la dernière version" /> Chargement…</Badge>
    {:else if releases.state === 'ok'}
      <Badge tone="ok">Dernière version : {releases.release.version}{releases.release.date ? ` — ${releases.release.date}` : ''}</Badge>
    {:else}
      <Badge tone="warn">Versions sur GitHub</Badge>
    {/if}
  </p>
  <p class="tagline">Minecraft, <span>sans compte Microsoft</span>.</p>
  <p class="lead">
    Launcher Minecraft Java Edition qui tourne <b>hors-ligne</b> : un pseudo suffit, rien n'est envoyé à Microsoft.
    Forge, Fabric, Quilt, NeoForge et OptiFine gérés nativement, et Java&nbsp;21 est déjà dans le paquet — il n'y a
    rien à installer à côté.
  </p>
  <p class="actions">
    <a class="go" href="#telecharger">Télécharger Cubox</a>
    <a href={RELEASES_URL} rel="noopener">Toutes les versions</a>
  </p>
</section>

<section id="telecharger" aria-labelledby="titre-telecharger">
  <h2 id="titre-telecharger"><span>#</span> Télécharger</h2>
  <p class="muted">Décompresse, lance, c'est tout. Java est inclus dans chaque archive.</p>

  {#if releases.state === 'loading'}
    <p class="muted"><Spinner label="Chargement des versions" /> Chargement des versions…</p>
  {:else if releases.state === 'ok'}
    <Downloads release={releases.release} />
  {:else}
    <!-- Never an empty section: the reason, and the direct link to the mirror. -->
    <div class="note err" role="alert">
      <b>Liste des versions indisponible</b>
      <p>
        {releases.message} — les téléchargements restent accessibles directement sur GitHub :
        <a href={RELEASES_URL} rel="noopener">{RELEASES_URL}</a>
      </p>
    </div>
  {/if}

  <div class="arch">
    <Panel title="Arch : mises à jour automatiques" tag="pacman">
      <pre class="install"><span>$</span> {INSTALL_ARCH}</pre>
      <p>Installe le dépôt pacman signé ; ensuite <code>yay -Syu</code> suffit.</p>
      <p>Le script affichera cette empreinte — <b>vérifie qu'elle correspond</b> :</p>
      <p><code class="fingerprint">{FINGERPRINT}</code></p>
      <p><a href={PACMAN_DOC} rel="noopener">Détails et installation manuelle</a></p>
    </Panel>
  </div>
</section>

<section id="nouveautes" aria-labelledby="titre-nouveautes">
  <h2 id="titre-nouveautes"><span>#</span> Nouveautés</h2>
  {#each CHANGES as entry, index (entry.version)}
    <details class="release" open={index === 0}>
      <summary><b>{entry.version}</b>{dateOf(entry.version) ? ` — ${dateOf(entry.version)}` : ''}</summary>
      <div class="notes">
        {#each entry.notes as block, at (at)}
          {#if block.kind === 'title'}<h3>{block.text}</h3>
          {:else if block.kind === 'item'}<p class="item">{block.text}</p>
          {:else}<p>{block.text}</p>{/if}
        {/each}
      </div>
    </details>
  {/each}
  <p class="muted"><a href="{MIRROR}/blob/main/CHANGELOG.md" rel="noopener">Tout le journal des versions</a></p>
</section>

<section id="fonctions" aria-labelledby="titre-fonctions">
  <h2 id="titre-fonctions"><span>#</span> Ce que fait Cubox</h2>
  <div class="grid">
    {#each FEATURES as feature (feature.tag)}
      <Panel title={feature.title} tag={feature.tag}><p class="text">{feature.text}</p></Panel>
    {/each}
  </div>
</section>

<section id="demarrer" aria-labelledby="titre-demarrer">
  <h2 id="titre-demarrer"><span>#</span> Bien démarrer</h2>
  <ol class="grid steps">
    {#each STEPS as step, index (step.title)}
      <li><Panel title={step.title} tag={String(index + 1)}><p class="text">{step.text}</p></Panel></li>
    {/each}
  </ol>

  <div class="note warn">
    <b>Serveurs premium</b>
    <p>
      Les serveurs qui exigent une vérification du compte Microsoft (Hypixel et consorts) <b>refuseront la connexion</b> :
      c'est une protection côté serveur qu'aucun launcher hors-ligne ne peut contourner, ce n'est pas un défaut de Cubox.
      Le solo, le LAN, tes propres serveurs et ceux en <code>online-mode=false</code> marchent parfaitement.
    </p>
  </div>

  <p class="actions">
    <a href="{MIRROR}/blob/main/docs/GUIDE_MINECRAFT_DEBUTANT.md" rel="noopener">Guide débutant</a>
    <a href="{MIRROR}/blob/main/CHANGELOG.md" rel="noopener">Nouveautés</a>
    <a href="{MIRROR}/issues" rel="noopener">Signaler un problème</a>
  </p>
</section>

<style>
  section { display: grid; gap: 14px; scroll-margin-top: 70px; min-width: 0; }
  h2 { font-size: 18px; }
  h2 span { color: var(--cx-accent); }
  p { margin: 0; }
  .muted { color: var(--cx-muted); }
  .hero { padding: 18px 0 6px; }
  .tagline { font-size: clamp(24px, 4.5vw, 40px); font-weight: 800; color: var(--cx-fg-strong); line-height: 1.2; }
  .tagline span { color: var(--cx-accent); text-shadow: var(--cx-glow); }
  .lead { max-width: 72ch; color: var(--cx-fg); }
  .lead b { color: var(--cx-fg-strong); }
  .actions { display: flex; flex-wrap: wrap; gap: 10px; }
  .actions a { padding: 7px 14px; border: 1px solid var(--cx-line); border-radius: var(--cx-radius-sm); background: var(--cx-panel-2); }
  .actions a:hover { text-decoration: none; border-color: var(--cx-muted); }
  .actions .go { background: var(--cx-accent); border-color: var(--cx-accent); color: var(--cx-bg); font-weight: 700; box-shadow: var(--cx-glow); }
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(230px, 1fr)); gap: 14px; }
  .steps { list-style: none; margin: 0; padding: 0; }
  .text { color: var(--cx-fg); }
  .arch :global(p) { margin: 6px 0 0; }
  .install { margin: 0; padding: 10px 12px; background: var(--cx-bg); border: 1px solid var(--cx-line); border-radius: var(--cx-radius-sm); white-space: pre-wrap; overflow-wrap: anywhere; color: var(--cx-fg-strong); font: inherit; }
  .install span { color: var(--cx-accent); }
  code { font: inherit; color: var(--cx-fg-strong); }
  .fingerprint { color: var(--cx-detail); overflow-wrap: anywhere; }
  .note { border: 1px solid var(--cx-line); border-left-width: 3px; border-radius: var(--cx-radius-sm); padding: 10px 14px; background: var(--cx-panel); }
  .note p { margin-top: 4px; overflow-wrap: anywhere; }
  .note.err { border-left-color: var(--cx-err); }
  .note.err b { color: var(--cx-err); }
  .note.warn { border-left-color: var(--cx-warn); }
  .note.warn > b { color: var(--cx-warn); }
  .release { border: 1px solid var(--cx-line); border-radius: var(--cx-radius-sm); background: var(--cx-panel); padding: 10px 14px; }
  .release summary { cursor: pointer; color: var(--cx-fg-strong); }
  .notes { display: grid; gap: 4px; margin-top: 8px; max-width: 72ch; }
  .notes h3 { font-size: 15px; margin: 8px 0 2px; color: var(--cx-fg-strong); }
  .notes .item { padding-left: 1.2em; text-indent: -1.2em; }
  .notes p { overflow-wrap: anywhere; }
  .notes .item::before { content: '- '; color: var(--cx-accent); }
</style>
