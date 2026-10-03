import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { cloudoxApp } from '@cloudox/socle/vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import { defineConfig } from 'vitest/config'

const REPO = new URL('../../', import.meta.url)

/**
 * In development, serves the two files the image takes from elsewhere in the repository
 * (site/Dockerfile copies them next to the build): the Cubox logo and the Arch install script.
 * @returns {import('vite').Plugin}
 */
function repoFiles() {
  /** @type {Record<string, [string, string]>} */
  const files = {
    '/cubox.png': ['HMCL/image/cubox.png', 'image/png'],
    '/install-arch.sh': ['packaging/arch/install-arch.sh', 'text/plain; charset=utf-8'],
  }
  return {
    name: 'cubox-repo-files',
    apply: 'serve',
    configureServer(server) {
      server.middlewares.use((request, response, next) => {
        const file = files[(request.url ?? '').split('?')[0]]
        if (!file) return next()
        response.setHeader('Content-Type', file[1])
        response.end(readFileSync(fileURLToPath(new URL(file[0], REPO))))
      })
    },
  }
}

// Same public mirror as the nginx relay in production (site/default.conf.template).
const RELEASES_REPO = process.env.CUBOX_RELEASES_REPO ?? 'yapixgs/Cubox-publique'

// The release notes come from the repository's own CHANGELOG.md (the source of
// truth, written with each release), embedded at build time: the GitHub release
// bodies only said « Publié automatiquement… ». site/Dockerfile copies it to /.
const CHANGELOG = readFileSync(fileURLToPath(new URL('CHANGELOG.md', REPO)), 'utf8')

export default defineConfig({
  define: { __CUBOX_CHANGELOG__: JSON.stringify(CHANGELOG) },
  plugins: [svelte(), cloudoxApp(), repoFiles()],
  server: {
    port: 5181,
    proxy: {
      '/api/releases': {
        target: 'https://api.github.com',
        changeOrigin: true,
        rewrite: () => `/repos/${RELEASES_REPO}/releases?per_page=5`,
        headers: { Accept: 'application/vnd.github+json', 'User-Agent': 'cubox-site' },
      },
    },
  },
  test: { include: ['tests/unit/**/*.test.js'], environment: 'node' },
})
