import { describe, expect, test } from 'vitest'
import { decrire, derniere, notesDe, notesDesVersions, sectionsDuJournal, taille } from '../../src/lib/versions.js'

/** @param {string} name */
const fichier = (name, size = 1) => ({ name, size, browser_download_url: `https://example.org/${name}` })

describe('derniere', () => {
  test('saute les brouillons et les préversions en tête', () => {
    expect(derniere([{ tag_name: 'v2', draft: true }, { tag_name: 'v2-rc', prerelease: true }, { tag_name: 'v1' }]).tag_name).toBe('v1')
  })
  test('retombe sur la première entrée quand rien n\'est publié', () => {
    expect(derniere([{ tag_name: 'v2-rc', prerelease: true }]).tag_name).toBe('v2-rc')
  })
  test('une liste vide est une erreur, pas une page vide', () => {
    expect(() => derniere([])).toThrow('aucune version publiée')
  })
})

describe('decrire', () => {
  test('un téléchargement par plateforme, reconnu aux noms de fabriquer-paquets.sh', () => {
    const version = decrire({
      tag_name: 'v1.3.3',
      assets: [fichier('Cubox-1.3.3-linux-x64.tar.gz'), fichier('Cubox-1.3.3-windows-x64.zip'), fichier('cubox-1.3.3-1-x86_64.pkg.tar.zst'), fichier('cubox.db'), fichier('Cubox-1.3.3-SHA256.txt')],
    })
    expect(version.telechargements.map((t) => [t.plateforme.cle, t.fichier?.name])).toEqual([
      ['windows', 'Cubox-1.3.3-windows-x64.zip'],
      ['linux', 'Cubox-1.3.3-linux-x64.tar.gz'],
      ['arch', 'cubox-1.3.3-1-x86_64.pkg.tar.zst'],
    ])
    expect(version.sommes?.name).toBe('Cubox-1.3.3-SHA256.txt')
  })
  test('un fichier sans nom est ignoré, sans erreur', () => {
    const version = decrire({ tag_name: 'v1', assets: [{ browser_download_url: 'x' }, fichier('Cubox-1-windows-x64.zip')] })
    expect(version.telechargements[0].fichier?.name).toBe('Cubox-1-windows-x64.zip')
  })
  test('une plateforme absente reste dans la liste, sans fichier', () => {
    const version = decrire({ tag_name: 'v1', assets: [fichier('Cubox-1-windows-x64.zip')] })
    expect(version.telechargements.find((t) => t.plateforme.cle === 'linux')?.fichier).toBeUndefined()
    expect(version.sommes).toBeUndefined()
  })
})

test('tailles en Mo avec une décimale, en Ko en dessous', () => {
  expect(taille(150 * 1024 * 1024)).toBe('150.0 Mo')
  expect(taille(2048)).toBe('2 Ko')
  expect(taille(undefined)).toBe('')
  expect(taille(0)).toBe('')
})

describe('notesDe', () => {
  test('transforme le markdown en blocs de texte, les liens gardent leur libellé', () => {
    expect(notesDe('## Titre\n- **Gras** et [lien](https://x)\n\nTexte _ici_\n<!-- caché -->')).toEqual([
      { genre: 'titre', texte: 'Titre' },
      { genre: 'element', texte: 'Gras et lien' },
      { genre: 'texte', texte: 'Texte ici' },
    ])
  })
  test('un corps vide ne donne aucun bloc', () => {
    expect(notesDe(undefined)).toEqual([])
  })
})

describe('sectionsDuJournal', () => {
  test('les dernières versions du CHANGELOG, éléments de liste recollés', () => {
    const md = '# Journal\n\n## 1.2.0\n\n### Ajouté\n- **Un** truc\n  sur deux lignes.\n\n## 1.1.0\n- Autre\n\n## 1.0.0\n- Vieux'
    expect(sectionsDuJournal(md, 2)).toEqual([
      { version: '1.2.0', notes: [{ genre: 'titre', texte: 'Ajouté' }, { genre: 'element', texte: 'Un truc sur deux lignes.' }] },
      { version: '1.1.0', notes: [{ genre: 'element', texte: 'Autre' }] },
    ])
  })
})

describe('notesDesVersions', () => {
  /** @typedef {import('../../src/lib/versions.js').Bloc} Bloc */
  /** @type {{ version: string, notes: Bloc[] }[]} */
  const archive = [
    { version: '1.3.3', notes: [{ genre: 'element', texte: 'Correctif archivé' }] },
    { version: '1.3.2', notes: [{ genre: 'element', texte: 'Ajout archivé' }] },
  ]
  test('les notes de la Release pour une version récente, le CHANGELOG pour les anciennes', () => {
    /** @type {{ version: string, date: string, notes: Bloc[] }[]} */
    const historique = [
      { version: 'v1.4.0', date: '22 octobre 2026', notes: [{ genre: 'element', texte: 'Notes de la Release' }] },
      { version: 'v1.3.3', date: '30 septembre 2026', notes: [{ genre: 'texte', texte: 'Publié automatiquement' }] },
    ]
    expect(notesDesVersions(historique, archive)).toEqual([
      { version: '1.4.0', date: '22 octobre 2026', notes: [{ genre: 'element', texte: 'Notes de la Release' }] },
      { version: '1.3.3', date: '30 septembre 2026', notes: [{ genre: 'element', texte: 'Correctif archivé' }] },
      { version: '1.3.2', date: '', notes: [{ genre: 'element', texte: 'Ajout archivé' }] },
    ])
  })
  test('sans réponse du miroir, le CHANGELOG seul', () => {
    expect(notesDesVersions(null, archive, 1)).toEqual([
      { version: '1.3.3', date: '', notes: [{ genre: 'element', texte: 'Correctif archivé' }] },
    ])
  })
})
