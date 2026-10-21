<!-- The download cards of the latest release, one per platform, and the checksums file. -->
<script>
  import { Button, Empty, Panel } from '@cloudox/socle'
  import { PACMAN_DOC, RELEASES_URL, size } from './releases.js'

  /** @type {{ release: ReturnType<typeof import('./releases.js').describe> }} */
  let { release } = $props()
</script>

<div class="cards">
  {#each release.downloads as { platform, asset } (platform.key)}
    <Panel title={platform.name} tag={platform.tag}>
      <div class="card" data-platform={platform.key}>
        {#if asset}
          <p class="meta">{platform.detail}{asset.size ? ` · ${size(asset.size)}` : ''}</p>
          <Button variant="primary" href={asset.browser_download_url}>Télécharger {release.version}</Button>
          <p class="hint"><span class="cmd">$</span> {platform.hint}</p>
          {#if platform.pacman}
            <a href={PACMAN_DOC} rel="noopener">Dépôt pacman → mises à jour automatiques</a>
          {/if}
        {:else}
          <!-- A missing package is said: a silently missing card would suggest the platform is unsupported. -->
          <Empty title="Pas de paquet {platform.name} dans {release.version}.">
            <Button variant="ghost" href={RELEASES_URL}>Voir les autres versions</Button>
          </Empty>
        {/if}
      </div>
    </Panel>
  {/each}
</div>

<!-- Discreet but present: a binary that cannot be checked is not a trusted binary. -->
{#if release.checksums}
  <p class="sums">
    Vérifier l'intégrité : <a href={release.checksums.browser_download_url} rel="noopener">{release.checksums.name}</a>
    · <code>sha256sum -c {release.checksums.name}</code>
  </p>
{/if}

<style>
  .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 14px; }
  .card { display: grid; gap: 10px; justify-items: start; }
  .meta { margin: 0; color: var(--cx-muted); }
  .hint { margin: 0; overflow-wrap: anywhere; }
  .cmd { color: var(--cx-accent); }
  .sums { color: var(--cx-muted); overflow-wrap: anywhere; }
  code { font: inherit; color: var(--cx-fg-strong); }
</style>
