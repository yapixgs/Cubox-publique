/**
 * The latest Cubox release, read from `/api/releases`.
 *
 * The source is the PUBLIC GitHub mirror, not the forge: the forge requires a
 * sign-in even for a public repository (anonymous 404 on the API, the repo page
 * and the assets — measured), so its links would be dead for every visitor.
 * nginx relays the call (site/default.conf.template): same origin, so the CSP
 * keeps `connect-src 'self'`, and one 5-minute cache for everyone, the anonymous
 * GitHub API being capped at 60 requests/hour per IP.
 */

export const MIRROR = 'https://github.com/yapixgs/Cubox-publique'
export const RELEASES_URL = `${MIRROR}/releases`
export const PACMAN_DOC = `${MIRROR}/blob/main/docs/DEPOT-PACMAN.md`

/**
 * @typedef {{ name?: string, size?: number, browser_download_url: string }} Asset
 * @typedef {{ tag_name?: string, name?: string, published_at?: string, draft?: boolean, prerelease?: boolean, assets?: Asset[] }} Release
 * @typedef {{ key: string, name: string, tag: string, detail: string, hint: string, pacman?: boolean, match: (name: string) => boolean }} Platform
 */

/**
 * The three platforms published by packaging/make-release.sh, matched on the asset names it produces.
 * @type {Platform[]}
 */
export const PLATFORMS = [
  {
    key: 'windows', name: 'Windows', tag: 'win', detail: 'x86-64 · Java inclus',
    hint: 'Décompresse, puis lance Installer.exe.',
    match: (name) => name.endsWith('-windows-x64.zip'),
  },
  {
    key: 'linux', name: 'Linux', tag: 'linux', detail: 'x86-64 · Java inclus',
    hint: 'Décompresse, puis lance ./install.sh.',
    match: (name) => name.endsWith('-linux-x64.tar.gz'),
  },
  {
    // The pacman repository is the real answer for Arch users: without it `yay -Syu`
    // does NOT update Cubox (the package is on the AUR under no name) and it stays frozen.
    key: 'arch', name: 'Arch Linux', tag: 'arch', detail: 'paquet pacman',
    hint: 'sudo pacman -U cubox-*.pkg.tar.zst', pacman: true,
    match: (name) => name.endsWith('.pkg.tar.zst'),
  },
]

/** Human-readable size, in Mo with one decimal (Ko below 1 Mo); empty when the API gives none. */
export function size(/** @type {number | undefined} */ bytes) {
  if (typeof bytes !== 'number' || bytes <= 0) return ''
  const mo = bytes / (1024 * 1024)
  return mo >= 1 ? `${mo.toFixed(1)} Mo` : `${Math.round(bytes / 1024)} Ko`
}

/**
 * The release to offer: the first published one, skipping drafts and pre-releases at the top.
 * @param {Release[] | Release} data the body of `/api/releases`
 */
export function latest(data) {
  const list = Array.isArray(data) ? data : [data]
  const release = list.find((r) => r && !r.draft && !r.prerelease) ?? list[0]
  if (!release) throw new Error('aucune version publiée')
  return release
}

/**
 * What the page shows of a release: version, date, one download per platform, the checksums file.
 * @param {Release} release
 */
export function describe(release) {
  const version = release.tag_name || release.name || ''
  const assets = release.assets ?? []
  const date = release.published_at
    ? new Date(release.published_at).toLocaleDateString('fr-FR', { year: 'numeric', month: 'long', day: 'numeric' })
    : ''
  return {
    version,
    date,
    downloads: PLATFORMS.map((platform) => ({ platform, asset: assets.find((a) => platform.match(a.name ?? '')) })),
    checksums: assets.find((a) => /SHA256.*\.txt$/i.test(a.name ?? '')),
  }
}

/** Fetches the latest release through the nginx relay. */
export async function fetchLatest() {
  const response = await fetch('/api/releases', { headers: { Accept: 'application/json' } })
  if (!response.ok) throw new Error(`le miroir a répondu ${response.status}`)
  return describe(latest(await response.json()))
}
