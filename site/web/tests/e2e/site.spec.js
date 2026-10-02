import { expect, test } from '@playwright/test'
import { BASE, fakeReleases } from './fake-releases.js'

test('the latest published version is shown, pre-releases skipped', async ({ page }) => {
  await fakeReleases(page)
  await page.goto('/')
  await expect(page.getByText('Dernière version : v1.3.3 — 30 septembre 2026')).toBeVisible()
  await expect(page.getByText(/1\.4\.0-rc1/)).toHaveCount(0)
})

test('three download cards point at the assets of the mirror, with their sizes', async ({ page }) => {
  await fakeReleases(page)
  await page.goto('/')
  const downloads = page.getByRole('link', { name: 'Télécharger v1.3.3' })
  await expect(downloads).toHaveCount(3)
  await expect(downloads.nth(0)).toHaveAttribute('href', `${BASE}/Cubox-1.3.3-windows-x64.zip`)
  await expect(downloads.nth(1)).toHaveAttribute('href', `${BASE}/Cubox-1.3.3-linux-x64.tar.gz`)
  await expect(downloads.nth(2)).toHaveAttribute('href', `${BASE}/cubox-1.3.3-1-x86_64.pkg.tar.zst`)
  await expect(page.locator('[data-platform="windows"]')).toContainText('x86-64 · Java inclus · 152.0 Mo')
  await expect(page.locator('[data-platform="linux"]')).toContainText('148.0 Mo')
  await expect(page.locator('[data-platform="arch"]')).toContainText('paquet pacman · 96.0 Mo')
  await expect(page.locator('[data-platform="arch"]').getByRole('link', { name: /Dépôt pacman/ })).toHaveAttribute(
    'href', 'https://github.com/yapixgs/Cubox-publique/blob/main/docs/DEPOT-PACMAN.md',
  )
})

test('the checksums file is linked, with the command to check it', async ({ page }) => {
  await fakeReleases(page)
  await page.goto('/')
  await expect(page.getByRole('link', { name: 'Cubox-1.3.3-SHA256.txt' })).toHaveAttribute('href', `${BASE}/Cubox-1.3.3-SHA256.txt`)
  await expect(page.getByText('sha256sum -c Cubox-1.3.3-SHA256.txt')).toBeVisible()
})

test('a platform missing from the release is said, not hidden', async ({ page }) => {
  await fakeReleases(page, { body: [{ tag_name: 'v1.3.3', assets: [{ name: 'Cubox-1.3.3-windows-x64.zip', size: 1e8, browser_download_url: `${BASE}/x.zip` }] }] })
  await page.goto('/')
  await expect(page.getByRole('link', { name: 'Télécharger v1.3.3' })).toHaveCount(1)
  await expect(page.getByText('Pas de paquet Linux dans v1.3.3.')).toBeVisible()
  await expect(page.getByText('Pas de paquet Arch Linux dans v1.3.3.')).toBeVisible()
})

test('the release API failing gives a clear message and the direct link to GitHub', async ({ page }) => {
  await fakeReleases(page, { status: 502, body: {} })
  await page.goto('/')
  const alert = page.getByRole('alert')
  await expect(alert).toContainText('Liste des versions indisponible')
  await expect(alert).toContainText('le miroir a répondu 502')
  await expect(alert.getByRole('link')).toHaveAttribute('href', 'https://github.com/yapixgs/Cubox-publique/releases')
  await expect(page.getByText('Versions sur GitHub')).toBeVisible()
  await expect(page.getByRole('link', { name: /^Télécharger v/ })).toHaveCount(0)
})

test('Cubox keeps its own logo, the Arch command and the features', async ({ page }) => {
  await fakeReleases(page)
  await page.goto('/')
  const logo = page.getByRole('link', { name: 'Cubox, accueil' }).locator('img')
  await expect(logo).toHaveAttribute('src', '/cubox.png')
  expect(await logo.evaluate((img) => /** @type {HTMLImageElement} */ (img).naturalWidth)).toBeGreaterThan(0)
  await expect(page.getByText('curl -fsSLO https://cubox.yabox.wasabout.net/install-arch.sh && bash install-arch.sh')).toBeVisible()
  await expect(page.getByText('6D5D EECF CD53 3845 32D6  1D66 7FC7 6ECD BCCF 57F2')).toBeVisible()
  for (const title of ['Mods et modpacks', 'Aucun compte', 'Skins persos', 'Windows, Linux, Arch', 'Installer', 'Choisir un pseudo', 'Jouer']) {
    await expect(page.getByRole('heading', { name: title })).toBeVisible()
  }
  await page.getByRole('navigation', { name: 'Sections' }).getByRole('link', { name: 'Fonctions' }).click()
  await expect(page).toHaveURL(/#fonctions$/)
})

test('mobile: no horizontal scroll, cards stacked', async ({ page, isMobile }) => {
  test.skip(!isMobile, 'mobile layout only')
  await fakeReleases(page)
  await page.goto('/')
  await expect(page.getByRole('link', { name: 'Télécharger v1.3.3' })).toHaveCount(3)
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth)
  expect(overflow).toBeLessThanOrEqual(0)
  const boxes = await Promise.all(['windows', 'linux', 'arch'].map((key) => page.locator(`[data-platform="${key}"]`).boundingBox()))
  expect(boxes[0]?.x).toBe(boxes[1]?.x)
  expect(/** @type {any} */ (boxes[1]).y).toBeGreaterThan(/** @type {any} */ (boxes[0]).y)
  await expect(page.getByRole('navigation', { name: 'Sections' }).getByRole('link', { name: 'Télécharger' })).toBeVisible()
})

test('desktop: the three cards side by side', async ({ page, isMobile }) => {
  test.skip(isMobile, 'desktop layout only')
  await fakeReleases(page)
  await page.goto('/')
  await expect(page.getByRole('link', { name: 'Télécharger v1.3.3' })).toHaveCount(3)
  const boxes = await Promise.all(['windows', 'linux', 'arch'].map((key) => page.locator(`[data-platform="${key}"]`).boundingBox()))
  expect(boxes[0]?.y).toBe(boxes[2]?.y)
})
