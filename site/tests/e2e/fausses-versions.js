/**
 * Un faux `/api/releases` : le relais nginx du miroir GitHub, avec les noms de fichiers
 * produits par packaging/fabriquer-paquets.sh.
 */
export const BASE = 'https://github.com/yapixgs/Cubox-publique/releases/download/v1.3.3'

/** @param {string} name @param {number} size */
const fichier = (name, size) => ({ name, size, browser_download_url: `${BASE}/${name}` })

export const VERSIONS = [
  { tag_name: 'v1.4.0-rc1', prerelease: true, assets: [fichier('Cubox-1.4.0-rc1-windows-x64.zip', 1)] },
  {
    tag_name: 'v1.3.3',
    published_at: '2026-09-30T10:00:00Z',
    assets: [
      fichier('Cubox-1.3.3-windows-x64.zip', 152 * 1024 * 1024),
      fichier('Cubox-1.3.3-linux-x64.tar.gz', 148 * 1024 * 1024),
      fichier('cubox-1.3.3-1-x86_64.pkg.tar.zst', 96 * 1024 * 1024),
      fichier('cubox.db', 900),
      fichier('Cubox-1.3.3-SHA256.txt', 400),
    ],
  },
]

/**
 * @param {import('@playwright/test').Page} page
 * @param {{ statut?: number, corps?: any }} [reponse]
 */
export async function simulerVersions(page, { statut = 200, corps = VERSIONS } = {}) {
  await page.route('**/api/releases', (route) => route.fulfill({ status: statut, contentType: 'application/json', body: JSON.stringify(corps) }))
}
