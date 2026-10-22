import { expect, test } from '@playwright/test'
import { BASE, VERSIONS, simulerVersions } from './fausses-versions.js'

test('la dernière version publiée est affichée, les préversions sautées', async ({ page }) => {
  await simulerVersions(page)
  await page.goto('/')
  await expect(page.getByText('Dernière version : v1.3.3 — 30 septembre 2026')).toBeVisible()
  await expect(page.getByText(/1\.4\.0-rc1/)).toHaveCount(0)
})

test('trois cartes de téléchargement pointent vers les fichiers du miroir, avec leur taille', async ({ page }) => {
  await simulerVersions(page)
  await page.goto('/')
  const telechargements = page.getByRole('link', { name: 'Télécharger v1.3.3' })
  await expect(telechargements).toHaveCount(3)
  await expect(telechargements.nth(0)).toHaveAttribute('href', `${BASE}/Cubox-1.3.3-windows-x64.zip`)
  await expect(telechargements.nth(1)).toHaveAttribute('href', `${BASE}/Cubox-1.3.3-linux-x64.tar.gz`)
  await expect(telechargements.nth(2)).toHaveAttribute('href', `${BASE}/cubox-1.3.3-1-x86_64.pkg.tar.zst`)
  await expect(page.locator('[data-plateforme="windows"]')).toContainText('x86-64 · Java inclus · 152.0 Mo')
  await expect(page.locator('[data-plateforme="linux"]')).toContainText('148.0 Mo')
  await expect(page.locator('[data-plateforme="arch"]')).toContainText('Paquet pacman · 96.0 Mo')
  await expect(page.locator('[data-plateforme="arch"]').getByRole('link', { name: /Dépôt pacman/ })).toHaveAttribute(
    'href', 'https://github.com/yapixgs/Cubox-publique/blob/main/docs/DEPOT-PACMAN.md',
  )
})

test('le fichier des sommes de contrôle est lié, avec la commande pour vérifier', async ({ page }) => {
  await simulerVersions(page)
  await page.goto('/')
  await expect(page.getByRole('link', { name: 'Cubox-1.3.3-SHA256.txt' })).toHaveAttribute('href', `${BASE}/Cubox-1.3.3-SHA256.txt`)
  await expect(page.getByText('sha256sum -c Cubox-1.3.3-SHA256.txt')).toBeVisible()
})

test('une plateforme absente de la version est signalée, pas cachée', async ({ page }) => {
  await simulerVersions(page, { corps: [{ tag_name: 'v1.3.3', assets: [{ name: 'Cubox-1.3.3-windows-x64.zip', size: 1e8, browser_download_url: `${BASE}/x.zip` }] }] })
  await page.goto('/')
  await expect(page.getByRole('link', { name: 'Télécharger v1.3.3' })).toHaveCount(1)
  await expect(page.getByText('Pas de paquet Linux dans v1.3.3.')).toBeVisible()
  await expect(page.getByText('Pas de paquet Arch Linux dans v1.3.3.')).toBeVisible()
})

test('une panne de l\'API des versions donne un message clair et le lien direct vers GitHub', async ({ page }) => {
  await simulerVersions(page, { statut: 502, corps: {} })
  await page.goto('/')
  const alerte = page.getByRole('alert')
  await expect(alerte).toContainText('Liste des versions indisponible')
  await expect(alerte).toContainText('le miroir a répondu 502')
  await expect(alerte.getByRole('link')).toHaveAttribute('href', 'https://github.com/yapixgs/Cubox-publique/releases')
  await expect(page.getByText('Versions sur GitHub')).toBeVisible()
  await expect(page.getByRole('link', { name: /^Télécharger v/ })).toHaveCount(0)
})

test('Cubox garde son logo, la commande Arch et les fonctions', async ({ page }) => {
  await simulerVersions(page)
  await page.goto('/')
  const logo = page.getByRole('link', { name: 'Cubox, accueil' }).locator('img')
  await expect(logo).toHaveAttribute('src', '/cubox.png')
  expect(await logo.evaluate((img) => /** @type {HTMLImageElement} */ (img).naturalWidth)).toBeGreaterThan(0)
  await expect(page.getByText('curl -fsSLO https://cubox.yabox.wasabout.net/install-arch.sh && bash install-arch.sh')).toBeVisible()
  await expect(page.getByText('6D5D EECF CD53 3845 32D6  1D66 7FC7 6ECD BCCF 57F2')).toBeVisible()
  for (const titre of ['Mods et modpacks', 'Aucun compte', 'Skins persos', 'Windows, Linux, Arch', 'Installer', 'Choisir un pseudo', 'Jouer']) {
    await expect(page.getByRole('heading', { name: titre })).toBeVisible()
  }
  await page.getByRole('navigation', { name: 'Sections' }).getByRole('link', { name: 'Fonctions' }).click()
  await expect(page).toHaveURL(/#fonctions$/)
})

test('mobile : pas de défilement horizontal, cartes empilées', async ({ page, isMobile }) => {
  test.skip(!isMobile, 'disposition mobile seulement')
  await simulerVersions(page)
  await page.goto('/')
  await expect(page.getByRole('link', { name: 'Télécharger v1.3.3' })).toHaveCount(3)
  const debordement = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth)
  expect(debordement).toBeLessThanOrEqual(0)
  const cadres = await Promise.all(['windows', 'linux', 'arch'].map((cle) => page.locator(`[data-plateforme="${cle}"]`).boundingBox()))
  expect(cadres[0]?.x).toBe(cadres[1]?.x)
  expect(/** @type {any} */ (cadres[1]).y).toBeGreaterThan(/** @type {any} */ (cadres[0]).y)
  await expect(page.getByRole('navigation', { name: 'Sections' }).getByRole('link', { name: 'Télécharger' })).toBeVisible()
})

test('bureau : les trois cartes côte à côte', async ({ page, isMobile }) => {
  test.skip(isMobile, 'disposition bureau seulement')
  await simulerVersions(page)
  await page.goto('/')
  await expect(page.getByRole('link', { name: 'Télécharger v1.3.3' })).toHaveCount(3)
  const cadres = await Promise.all(['windows', 'linux', 'arch'].map((cle) => page.locator(`[data-plateforme="${cle}"]`).boundingBox()))
  expect(cadres[0]?.y).toBe(cadres[2]?.y)
})

test('les notes viennent du CHANGELOG, la plus récente ouverte, datée par la version', async ({ page }) => {
  await simulerVersions(page)
  await page.goto('/')
  const notes = page.locator('#nouveautes')
  await expect(notes.locator('details').first()).toHaveAttribute('open', '')
  await expect(notes.locator('details')).toHaveCount(3)
  await expect(notes.locator('summary').first()).toContainText('1.3.3')
  await expect(notes.locator('summary').first()).toContainText('30 septembre 2026')
  await expect(notes.getByRole('heading', { level: 3 }).first()).toBeVisible()
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth)).toBe(true)
})

test('une version livrée après la v1.4.0 montre les notes de sa Release', async ({ page }) => {
  const nouvelle = {
    tag_name: 'v1.4.0',
    published_at: '2026-10-22T10:00:00Z',
    body: '## Ajouts\n- **site :** notes de version lues sur le miroir',
    assets: [],
  }
  await simulerVersions(page, { corps: [nouvelle, ...VERSIONS] })
  await page.goto('/')
  const notes = page.locator('#nouveautes')
  await expect(notes.locator('summary').first()).toContainText('1.4.0')
  await expect(notes.locator('summary').first()).toContainText('22 octobre 2026')
  await expect(notes.getByText('site : notes de version lues sur le miroir')).toBeVisible()
  await expect(notes.locator('summary').nth(1)).toContainText('1.3.3')
})
