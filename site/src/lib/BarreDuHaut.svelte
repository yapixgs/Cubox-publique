<!-- Barre du haut de la page publique : Cubox garde son propre logo (règle de Yann), les ancres de la page. -->
<script>
  import { MIROIR } from './versions.js'
</script>

<header class="barre">
  <a class="marque" href="/" aria-label="Cubox, accueil">
    <img src="/cubox.png" alt="" width="34" height="34" />
    <span>Cubox <small>by Cloudox</small></span>
  </a>
  <nav aria-label="Sections">
    <a href="#telecharger">Télécharger</a>
    <a href="#fonctions">Fonctions</a>
    <a href="#demarrer">Démarrer</a>
    <a class="externe" href={MIROIR} rel="noopener">Code source</a>
  </nav>
</header>

<style>
  .barre {
    position: sticky; top: 0; z-index: 10; display: flex; align-items: center; gap: 18px; padding: 10px 22px;
    border-bottom: 1px solid var(--cx-line); background: var(--cx-panel); flex-wrap: wrap;
  }
  .marque { display: flex; align-items: center; gap: 10px; font-weight: 800; font-size: 17px; color: var(--cx-fg-strong); }
  .marque:hover { text-decoration: none; }
  .marque img { image-rendering: pixelated; }
  small { color: var(--cx-muted); font-weight: 400; font-size: 12px; }
  nav { margin-left: auto; display: flex; gap: 4px; overflow-x: auto; }
  nav a { padding: 6px 10px; color: var(--cx-muted); white-space: nowrap; border-radius: var(--cx-radius-sm); }
  nav a:hover { color: var(--cx-fg-strong); text-decoration: none; background: var(--cx-panel-2); }
  .externe { color: var(--cx-info); border: 1px solid var(--cx-line); }
  @media (max-width: 600px) {
    .barre { padding: 8px 14px; gap: 6px; }
    nav { margin-left: 0; flex-basis: 100%; }
    nav a { padding: 4px 8px; }
  }
</style>
