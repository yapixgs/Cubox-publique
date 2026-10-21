<script>
  import { onMount } from 'svelte'
  import { MIRROR } from './lib/releases.js'
  import TopBar from './lib/TopBar.svelte'
  import HomePage from './pages/HomePage.svelte'

  // The socle Shell is not used: it loads the signed-in user, and this public page has no sign-in.
  onMount(() => document.body.classList.add('cx-crt'))
</script>

<TopBar />
<main>
  <HomePage />
</main>
<footer>
  <p>
    <b>Cubox</b> — fork non-officiel de <a href="https://github.com/HMCL-dev/HMCL" rel="noopener">HMCL</a>, sous licence
    <a href="{MIRROR}/blob/main/LICENSE" rel="noopener">GPLv3</a>. Sans affiliation avec Mojang, Microsoft ou l'équipe HMCL.
  </p>
  <p>
    <a href={MIRROR} rel="noopener">Code source</a> ·
    <a href="{MIRROR}/blob/main/docs/EULA.md" rel="noopener">Conditions d'utilisation</a> ·
    <a href="{MIRROR}/blob/main/docs/ROADMAP.md" rel="noopener">Feuille de route</a> ·
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
