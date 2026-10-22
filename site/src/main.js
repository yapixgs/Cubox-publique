import { mount } from 'svelte'
import App from './App.svelte'

// Pas de `loadConfig()` : la page publique n'a aucun réglage à l'exécution, l'image ne sert donc pas de /config.json.
mount(App, { target: /** @type {HTMLElement} */ (document.getElementById('app')) })
