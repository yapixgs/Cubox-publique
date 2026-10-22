/**
 * La dernière version de Cubox, lue sur `/api/releases`.
 *
 * La source est le miroir PUBLIC GitHub, pas la forge : la forge exige une connexion
 * même pour un dépôt public (404 anonyme sur l'API, la page du dépôt et les fichiers —
 * mesuré), ses liens seraient donc morts pour chaque visiteur. nginx relaie l'appel
 * (site/nginx/default.conf.template) : même origine, donc la CSP garde
 * `connect-src 'self'`, et un seul cache de 5 minutes pour tous, l'API GitHub anonyme
 * étant limitée à 60 requêtes par heure et par IP.
 */

export const MIROIR = 'https://github.com/yapixgs/Cubox-publique'
export const ADRESSE_VERSIONS = `${MIROIR}/releases`
export const DOC_PACMAN = `${MIROIR}/blob/main/docs/DEPOT-PACMAN.md`

/**
 * Les champs lus dans la réponse de l'API GitHub (contrat externe, noms anglais).
 * @typedef {{ name?: string, size?: number, browser_download_url: string }} FichierGithub
 * @typedef {{ tag_name?: string, name?: string, body?: string, published_at?: string, draft?: boolean, prerelease?: boolean, assets?: FichierGithub[] }} VersionGithub
 * @typedef {{ cle: string, nom: string, etiquette: string, detail: string, conseil: string, pacman?: boolean, correspond: (nom: string) => boolean }} Plateforme
 * @typedef {{ genre: 'titre' | 'element' | 'texte', texte: string }} Bloc
 */

/**
 * Les trois plateformes publiées par packaging/fabriquer-paquets.sh, reconnues aux noms
 * des fichiers qu'il produit.
 * @type {Plateforme[]}
 */
export const PLATEFORMES = [
  {
    cle: 'windows', nom: 'Windows', etiquette: 'ZIP', detail: 'x86-64 · Java inclus',
    conseil: 'Décompresse, puis lance Installer.exe.',
    correspond: (nom) => nom.endsWith('-windows-x64.zip'),
  },
  {
    cle: 'linux', nom: 'Linux', etiquette: 'TAR.GZ', detail: 'x86-64 · Java inclus',
    conseil: 'Décompresse, puis lance ./install.sh.',
    correspond: (nom) => nom.endsWith('-linux-x64.tar.gz'),
  },
  {
    // Le dépôt pacman est la vraie réponse pour Arch : sans lui, `yay -Syu` ne met PAS
    // Cubox à jour (le paquet n'est sur l'AUR sous aucun nom) et il reste figé.
    cle: 'arch', nom: 'Arch Linux', etiquette: 'Pacman', detail: 'Paquet pacman',
    conseil: 'sudo pacman -U cubox-*.pkg.tar.zst', pacman: true,
    correspond: (nom) => nom.endsWith('.pkg.tar.zst'),
  },
]

/** Taille lisible, en Mo avec une décimale (Ko sous 1 Mo) ; vide quand l'API n'en donne pas. */
export function taille(/** @type {number | undefined} */ octets) {
  if (typeof octets !== 'number' || octets <= 0) return ''
  const mo = octets / (1024 * 1024)
  return mo >= 1 ? `${mo.toFixed(1)} Mo` : `${Math.round(octets / 1024)} Ko`
}

/**
 * La version à proposer : la première publiée, en sautant brouillons et préversions en tête.
 * @param {VersionGithub[] | VersionGithub} donnees le corps de `/api/releases`
 */
export function derniere(donnees) {
  const liste = Array.isArray(donnees) ? donnees : [donnees]
  const version = liste.find((v) => v && !v.draft && !v.prerelease) ?? liste[0]
  if (!version) throw new Error('aucune version publiée')
  return version
}

/**
 * Ce que la page montre d'une version : numéro, date, un téléchargement par plateforme,
 * le fichier des sommes de contrôle.
 * @param {VersionGithub} version
 */
export function decrire(version) {
  const numero = version.tag_name || version.name || ''
  const fichiers = version.assets ?? []
  const date = version.published_at
    ? new Date(version.published_at).toLocaleDateString('fr-FR', { year: 'numeric', month: 'long', day: 'numeric' })
    : ''
  return {
    version: numero,
    date,
    telechargements: PLATEFORMES.map((plateforme) => ({ plateforme, fichier: fichiers.find((f) => plateforme.correspond(f.name ?? '')) })),
    sommes: fichiers.find((f) => /SHA256.*\.txt$/i.test(f.name ?? '')),
  }
}

/**
 * Les notes de version en blocs de texte, jamais en HTML : le corps vient de GitHub et
 * s'affiche comme du texte (titres, éléments de liste, paragraphes). Les liens Markdown
 * gardent leur libellé, les marques d'emphase disparaissent.
 * @param {string | undefined} corps
 * @returns {Bloc[]}
 */
export function notesDe(corps) {
  const nettoyer = (/** @type {string} */ ligne) =>
    ligne.replace(/\[([^\]]+)\]\([^)]*\)/g, '$1').replace(/[*_`]+/g, '').trim()
  /** @type {Bloc[]} */
  const blocs = []
  for (const brute of (corps ?? '').split(/\r?\n/)) {
    const ligne = brute.trim()
    if (!ligne || /^<!--/.test(ligne)) continue
    if (/^#{1,6}\s/.test(ligne)) blocs.push({ genre: 'titre', texte: nettoyer(ligne.replace(/^#+\s*/, '')) })
    else if (/^[-*+]\s/.test(ligne)) blocs.push({ genre: 'element', texte: nettoyer(ligne.slice(2)) })
    else blocs.push({ genre: 'texte', texte: nettoyer(ligne) })
  }
  return blocs.filter((bloc) => bloc.texte)
}

/**
 * La dernière version à télécharger, et les notes des `nombre` dernières publiées.
 * @param {number} [nombre]
 */
export async function chargerVersions(nombre = 3) {
  const reponse = await fetch('/api/releases', { headers: { Accept: 'application/json' } })
  if (!reponse.ok) throw new Error(`le miroir a répondu ${reponse.status}`)
  /** @type {VersionGithub[] | VersionGithub} */
  const donnees = await reponse.json()
  const liste = (Array.isArray(donnees) ? donnees : [donnees]).filter((v) => v && !v.draft && !v.prerelease)
  return {
    derniere: decrire(derniere(donnees)),
    historique: liste.slice(0, nombre).map((version) => ({ ...decrire(version), notes: notesDe(version.body) })),
  }
}

/**
 * Les sections de CHANGELOG.md (« ## 1.3.3 »), les plus récentes d'abord, en blocs de texte.
 * @param {string} markdown
 * @param {number} [nombre]
 * @returns {{ version: string, notes: Bloc[] }[]}
 */
export function sectionsDuJournal(markdown, nombre = 3) {
  /** @type {{ version: string, lignes: string[] }[]} */
  const sections = []
  for (const ligne of (markdown ?? '').split(/\r?\n/)) {
    const titre = /^##\s+v?(\d+\.\d+(?:\.\d+)?\S*)/.exec(ligne)
    if (titre) { sections.push({ version: titre[1], lignes: [] }); continue }
    const courante = sections.at(-1)
    if (courante) courante.lignes.push(ligne)
  }
  return sections.slice(0, nombre).map((section) => ({ version: section.version, notes: recollerLesSuites(notesDe(section.lignes.join('\n'))) }))
}

/** Un élément de liste écrit sur plusieurs lignes arrive en élément puis en lignes de texte : les recoller. */
function recollerLesSuites(/** @type {Bloc[]} */ blocs) {
  /** @type {Bloc[]} */
  const recolles = []
  for (const bloc of blocs) {
    const precedent = recolles.at(-1)
    if (bloc.genre === 'texte' && precedent && precedent.genre !== 'titre') precedent.texte += ' ' + bloc.texte
    else recolles.push({ ...bloc })
  }
  return recolles
}

/**
 * Les notes des dernières versions, les plus récentes d'abord. Depuis la v1.4.0, les notes
 * d'une version sont celles de sa Release (R4.9) ; les versions antérieures gardent leur
 * section du CHANGELOG.md, figé. Sans réponse du miroir, le CHANGELOG seul.
 * @param {{ version: string, date: string, notes: Bloc[] }[] | null} historique les versions publiées sur le miroir
 * @param {{ version: string, notes: Bloc[] }[]} archive les sections du CHANGELOG
 * @param {number} [nombre]
 */
export function notesDesVersions(historique, archive, nombre = 3) {
  const publiees = (historique ?? []).map((entree) => {
    const version = entree.version.replace(/^v/, '')
    const ancienne = archive.find((section) => section.version === version)
    return { version, date: entree.date, notes: ancienne?.notes ?? entree.notes }
  })
  const connues = new Set(publiees.map((entree) => entree.version))
  const completees = archive
    .filter((section) => !connues.has(section.version))
    .map((section) => ({ ...section, date: '' }))
  return [...publiees, ...completees].slice(0, nombre)
}
