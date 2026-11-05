/**
 * Prépare la configuration nginx de l'image (R9.3), après `vite build` : rien ne s'exécute
 * dans l'image, la CSP reçoit donc ici l'empreinte de l'import map, seul script inline
 * de la page (cloudoxApp()). Sans elle, le navigateur la refuse et la page reste blanche.
 * Sortie : .construction/securite.conf, que le Dockerfile copie.
 */
import { mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs'

const empreinte = readFileSync('dist/importmap.sha256', 'utf8').trim()
if (!/^'sha256-[A-Za-z0-9+/]+=*'$/.test(empreinte)) {
  throw new Error(`empreinte d'import map illisible : ${empreinte}`)
}
const securite = readFileSync('nginx/securite.conf', 'utf8').replaceAll('@IMPORTMAP_SHA256@', empreinte)
mkdirSync('.construction', { recursive: true })
writeFileSync('.construction/securite.conf', securite)
// L'empreinte n'a rien à faire dans le site servi.
rmSync('dist/importmap.sha256')
// Le logo et le script d'installation Arch (adresse donnée aux gens) doivent être servis.
for (const fichier of ['dist/cubox.png', 'dist/install-arch.sh']) {
  if (!statSync(fichier).size) throw new Error(`${fichier} est vide`)
}
