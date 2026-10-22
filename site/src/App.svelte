<script>
  import { onMount } from 'svelte'
  import { MIROIR } from './lib/versions.js'
  import BarreDuHaut from './lib/BarreDuHaut.svelte'
  import PageAccueil from './pages/PageAccueil.svelte'

  // Pas de Shell du socle : il charge la personne connectée, et cette page publique n'a pas de connexion.
  onMount(() => document.body.classList.add('cx-crt'))
</script>

<BarreDuHaut />
<main>
  <PageAccueil />
</main>
<footer>
  <p>
    <b>Cubox</b> — fork non-officiel de <a href="https://github.com/HMCL-dev/HMCL" rel="noopener">HMCL</a>, sous licence
    <a href="{MIROIR}/blob/main/LICENSE" rel="noopener">GPLv3</a>. Sans affiliation avec Mojang, Microsoft ou l'équipe HMCL.
  </p>
  <p>
    <a href={MIROIR} rel="noopener">Code source</a> ·
    <a href="{MIROIR}/blob/main/docs/EULA.md" rel="noopener">Conditions d'utilisation</a> ·
    <a href="{MIROIR}/blob/main/docs/ROADMAP.md" rel="noopener">Feuille de route</a> ·
    hébergé par Cloudox
  </p>
</footer>

<style>
  main { max-width: 1100px; margin: 0 auto; padding: 22px; display: grid; gap: 40px; }
  footer { max-width: 1100px; margin: 0 auto; padding: 18px 22px 30px; border-top: 1px solid var(--cx-line); color: var(--cx-muted); font-size: 12px; }
  footer p { margin: 4px 0; }
  footer b { color: var(--cx-fg); }
  @media (max-width: 600px) { main { padding: 14px; gap: 30px; } footer { padding: 14px; } }
</style>
