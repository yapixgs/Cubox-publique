import { mount } from 'svelte'
import App from './App.svelte'

// No `loadConfig()`: the public page has no runtime setting, so the image serves no /config.json.
mount(App, { target: /** @type {HTMLElement} */ (document.getElementById('app')) })
