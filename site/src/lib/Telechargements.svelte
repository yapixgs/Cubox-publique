<!-- Les cartes de téléchargement de la dernière version, une par plateforme, et le fichier des sommes de contrôle. -->
<script>
  import { Button, Empty, Panel } from '@cloudox/socle'
  import { ADRESSE_VERSIONS, DOC_PACMAN, taille } from './versions.js'

  /** @type {{ version: ReturnType<typeof import('./versions.js').decrire> }} */
  let { version } = $props()
</script>

<div class="cartes">
  {#each version.telechargements as { plateforme, fichier } (plateforme.cle)}
    <Panel title={plateforme.nom} tag={plateforme.etiquette}>
      <div class="carte" data-plateforme={plateforme.cle}>
        {#if fichier}
          <p class="details">{plateforme.detail}{fichier.size ? ` · ${taille(fichier.size)}` : ''}</p>
          <Button variant="primary" href={fichier.browser_download_url}>Télécharger {version.version}</Button>
          <p class="conseil"><span class="invite">$</span> {plateforme.conseil}</p>
          {#if plateforme.pacman}
            <a href={DOC_PACMAN} rel="noopener">Dépôt pacman → mises à jour automatiques</a>
          {/if}
        {:else}
          <!-- Un paquet manquant est dit : une carte absente laisserait croire la plateforme abandonnée. -->
          <Empty title="Pas de paquet {plateforme.nom} dans {version.version}.">
            <Button variant="ghost" href={ADRESSE_VERSIONS}>Voir les autres versions</Button>
          </Empty>
        {/if}
      </div>
    </Panel>
  {/each}
</div>

<!-- Discret mais présent : un binaire qu'on ne peut pas vérifier n'est pas un binaire de confiance. -->
{#if version.sommes}
  <p class="sommes">
    Vérifier l'intégrité : <a href={version.sommes.browser_download_url} rel="noopener">{version.sommes.name}</a>
    · <code>sha256sum -c {version.sommes.name}</code>
  </p>
{/if}

<style>
  .cartes { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 14px; }
  .carte { display: grid; gap: 10px; justify-items: start; }
  .details { margin: 0; color: var(--cx-muted); }
  .conseil { margin: 0; overflow-wrap: anywhere; }
  .invite { color: var(--cx-accent); }
  .sommes { color: var(--cx-muted); overflow-wrap: anywhere; }
  code { font: inherit; color: var(--cx-fg-strong); }
</style>
