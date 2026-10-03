/**
 * A fake `/api/releases`: the nginx relay of the GitHub mirror, with the asset names
 * produced by packaging/make-release.sh.
 */
export const BASE = 'https://github.com/yapixgs/Cubox-publique/releases/download/v1.3.3'

/** @param {string} name @param {number} size */
const asset = (name, size) => ({ name, size, browser_download_url: `${BASE}/${name}` })

export const RELEASES = [
  { tag_name: 'v1.4.0-rc1', prerelease: true, assets: [asset('Cubox-1.4.0-rc1-windows-x64.zip', 1)] },
  {
    tag_name: 'v1.3.3',
    body: '## Nouveautés\n- **Modrinth** : [navigateur](https://x) intégré\n<script>alert(1)</script>',
    published_at: '2026-09-30T10:00:00Z',
    assets: [
      asset('Cubox-1.3.3-windows-x64.zip', 152 * 1024 * 1024),
      asset('Cubox-1.3.3-linux-x64.tar.gz', 148 * 1024 * 1024),
      asset('cubox-1.3.3-1-x86_64.pkg.tar.zst', 96 * 1024 * 1024),
      asset('cubox.db', 900),
      asset('Cubox-1.3.3-SHA256.txt', 400),
    ],
  },
]

/**
 * @param {import('@playwright/test').Page} page
 * @param {{ status?: number, body?: any }} [answer]
 */
export async function fakeReleases(page, { status = 200, body = RELEASES } = {}) {
  await page.route('**/api/releases', (route) => route.fulfill({ status, contentType: 'application/json', body: JSON.stringify(body) }))
}
