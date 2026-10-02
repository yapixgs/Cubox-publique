import { describe as group, expect, test } from 'vitest'
import { describe, latest, size } from '../../src/lib/releases.js'

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
