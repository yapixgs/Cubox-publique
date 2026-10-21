import { describe as group, expect, test } from 'vitest'
import { describe, latest, size, notesOf, changelogSections, notesDesVersions } from '../../src/lib/releases.js'

/** @param {string} name */
const asset = (name, bytes = 1) => ({ name, size: bytes, browser_download_url: `https://example.org/${name}` })

group('latest', () => {
  test('skips drafts and pre-releases at the top', () => {
    expect(latest([{ tag_name: 'v2', draft: true }, { tag_name: 'v2-rc', prerelease: true }, { tag_name: 'v1' }]).tag_name).toBe('v1')
  })
  test('falls back to the first entry when nothing is published', () => {
    expect(latest([{ tag_name: 'v2-rc', prerelease: true }]).tag_name).toBe('v2-rc')
  })
  test('an empty list is an error, not an empty page', () => {
    expect(() => latest([])).toThrow('aucune version publiée')
  })
})

group('describe', () => {
  test('one download per platform, matched on the names of make-release.sh', () => {
    const release = describe({
      tag_name: 'v1.3.3',
      assets: [asset('Cubox-1.3.3-linux-x64.tar.gz'), asset('Cubox-1.3.3-windows-x64.zip'), asset('cubox-1.3.3-1-x86_64.pkg.tar.zst'), asset('cubox.db'), asset('Cubox-1.3.3-SHA256.txt')],
    })
    expect(release.downloads.map((d) => [d.platform.key, d.asset?.name])).toEqual([
      ['windows', 'Cubox-1.3.3-windows-x64.zip'],
      ['linux', 'Cubox-1.3.3-linux-x64.tar.gz'],
      ['arch', 'cubox-1.3.3-1-x86_64.pkg.tar.zst'],
    ])
    expect(release.checksums?.name).toBe('Cubox-1.3.3-SHA256.txt')
  })
  test('an asset without a name is ignored, not fatal', () => {
    const release = describe({ tag_name: 'v1', assets: [{ browser_download_url: 'x' }, asset('Cubox-1-windows-x64.zip')] })
    expect(release.downloads[0].asset?.name).toBe('Cubox-1-windows-x64.zip')
  })
  test('a missing platform stays in the list, without asset', () => {
    const release = describe({ tag_name: 'v1', assets: [asset('Cubox-1-windows-x64.zip')] })
    expect(release.downloads.find((d) => d.platform.key === 'linux')?.asset).toBeUndefined()
    expect(release.checksums).toBeUndefined()
  })
})

test('sizes in Mo with one decimal, Ko below', () => {
  expect(size(150 * 1024 * 1024)).toBe('150.0 Mo')
  expect(size(2048)).toBe('2 Ko')
  expect(size(undefined)).toBe('')
  expect(size(0)).toBe('')
})

group('notesOf', () => {
  test('turns markdown into plain blocks, links keep their label', () => {
    expect(notesOf('## Titre\n- **Gras** et [lien](https://x)\n\nTexte _ici_\n<!-- caché -->')).toEqual([
      { kind: 'title', text: 'Titre' },
      { kind: 'item', text: 'Gras et lien' },
      { kind: 'text', text: 'Texte ici' },
    ])
  })
  test('an empty body gives no block', () => {
    expect(notesOf(undefined)).toEqual([])
  })
})

group('changelogSections', () => {
  test('the last versions of the CHANGELOG, list items glued back together', () => {
    const md = '# Journal\n\n## 1.2.0\n\n### Ajouté\n- **Un** truc\n  sur deux lignes.\n\n## 1.1.0\n- Autre\n\n## 1.0.0\n- Vieux'
    expect(changelogSections(md, 2)).toEqual([
      { version: '1.2.0', notes: [{ kind: 'title', text: 'Ajouté' }, { kind: 'item', text: 'Un truc sur deux lignes.' }] },
      { version: '1.1.0', notes: [{ kind: 'item', text: 'Autre' }] },
    ])
  })
})

group('notesDesVersions', () => {
  /** @typedef {{ kind: 'title' | 'item' | 'text', text: string }} Bloc */
  /** @type {{ version: string, notes: Bloc[] }[]} */
  const archive = [
    { version: '1.3.3', notes: [{ kind: 'item', text: 'Correctif archivé' }] },
    { version: '1.3.2', notes: [{ kind: 'item', text: 'Ajout archivé' }] },
  ]
  test('les notes de la Release pour une version récente, le CHANGELOG pour les anciennes', () => {
    /** @type {{ version: string, date: string, notes: Bloc[] }[]} */
    const historique = [
      { version: 'v1.4.0', date: '22 octobre 2026', notes: [{ kind: 'item', text: 'Notes de la Release' }] },
      { version: 'v1.3.3', date: '30 septembre 2026', notes: [{ kind: 'text', text: 'Publié automatiquement' }] },
    ]
    expect(notesDesVersions(historique, archive)).toEqual([
      { version: '1.4.0', date: '22 octobre 2026', notes: [{ kind: 'item', text: 'Notes de la Release' }] },
      { version: '1.3.3', date: '30 septembre 2026', notes: [{ kind: 'item', text: 'Correctif archivé' }] },
      { version: '1.3.2', date: '', notes: [{ kind: 'item', text: 'Ajout archivé' }] },
    ])
  })
  test('sans réponse du miroir, le CHANGELOG seul', () => {
    expect(notesDesVersions(null, archive, 1)).toEqual([
      { version: '1.3.3', date: '', notes: [{ kind: 'item', text: 'Correctif archivé' }] },
    ])
  })
})
