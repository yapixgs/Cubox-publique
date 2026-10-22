import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { cloudoxApp } from '@cloudox/socle/vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import { defineConfig } from 'vitest/config'

const RACINE = new URL('../', import.meta.url)

/**
 * Les deux fichiers du site qui vivent ailleurs dans le dépôt : le logo de Cubox et le
 * script d'installation Arch. Servis tels quels en développement, copiés dans `dist/` au
 * build : l'image ne fait que copier `dist/` (R9.3).
 * @returns {import('vite').Plugin}
 */
function fichiersDuDepot() {
  /** @type {Record<string, [string, string]>} */
  const fichiers = {
    '/cubox.png': ['HMCL/image/cubox.png', 'image/png'],
    '/install-arch.sh': ['packaging/arch/install-arch.sh', 'text/plain; charset=utf-8'],
  }
  /** @param {string} chemin */
  const lire = (chemin) => readFileSync(fileURLToPath(new URL(chemin, RACINE)))
  return {
    name: 'cubox-fichiers-du-depot',
    configureServer(server) {
      server.middlewares.use((requete, reponse, suite) => {
        const fichier = fichiers[(requete.url ?? '').split('?')[0]]
        if (!fichier) return suite()
        reponse.setHeader('Content-Type', fichier[1])
        reponse.end(lire(fichier[0]))
      })
    },
    generateBundle() {
      for (const [adresse, [chemin]] of Object.entries(fichiers)) {
        this.emitFile({ type: 'asset', fileName: adresse.slice(1), source: lire(chemin) })
      }
    },
  }
}

// Le même miroir public que le relais nginx en production (site/nginx/default.conf.template).
const DEPOT_DES_VERSIONS = process.env.CUBOX_RELEASES_REPO ?? 'yapixgs/Cubox-publique'

// CHANGELOG.md du dépôt, figé, embarqué au build : il garde les notes des versions
// antérieures à la v1.4.0, dont les Releases GitHub ne disaient que « Publié automatiquement… ».
const JOURNAL = readFileSync(fileURLToPath(new URL('CHANGELOG.md', RACINE)), 'utf8')

export default defineConfig({
  define: { __JOURNAL_CUBOX__: JSON.stringify(JOURNAL) },
  plugins: [svelte(), cloudoxApp(), fichiersDuDepot()],
  server: {
    port: 5181,
    proxy: {
      '/api/releases': {
        target: 'https://api.github.com',
        changeOrigin: true,
        rewrite: () => `/repos/${DEPOT_DES_VERSIONS}/releases?per_page=5`,
        headers: { Accept: 'application/vnd.github+json', 'User-Agent': 'cubox-site' },
      },
    },
  },
  test: { include: ['tests/unit/**/*.test.js'], environment: 'node' },
})
