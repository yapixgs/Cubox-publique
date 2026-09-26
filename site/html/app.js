/* Remplit la section « Télécharger » depuis la dernière release publiée.
 *
 * La source est le MIROIR PUBLIC GitHub, pas la forge : la forge exige une
 * connexion même pour un dépôt public, et renvoie 404 en anonyme sur l'API,
 * la page du dépôt et les assets (mesuré). Les liens seraient morts pour tout
 * visiteur. Voir l'en-tête de site/default.conf.template pour le détail.
 *
 * L'appel passe par `/api/releases`, relayé par nginx : cela met la requête en
 * même origine (donc CSP `connect-src 'self'`) et surtout mutualise le cache,
 * l'API GitHub anonyme étant plafonnée à 60 requêtes/heure et par IP.
 */

// Les trois plateformes publiées par packaging/make-release.sh.
// `match` est testé sur le nom de l'asset tel que produit par ce script.
const PLATEFORMES = [
  {
    cle: 'windows',
    ico: '🪟',
    nom: 'Windows',
    detail: 'x86-64 · Java inclus',
    hint: 'Décompresse, puis lance Installer.exe.',
    match: (n) => n.endsWith('-windows-x64.zip'),
  },
  {
    cle: 'linux',
    ico: '🐧',
    nom: 'Linux',
    detail: 'x86-64 · Java inclus',
    hint: 'Décompresse, puis lance ./install.sh.',
    match: (n) => n.endsWith('-linux-x64.tar.gz'),
  },
  {
    cle: 'arch',
    ico: '📦',
    nom: 'Arch Linux',
    detail: 'paquet pacman',
    hint: 'sudo pacman -U cubox-*.pkg.tar.zst',
    match: (n) => n.endsWith('.pkg.tar.zst'),
  },
];

const RELEASES_URL = 'https://github.com/yapixgs/Cubox-publique/releases';

/** Formate une taille en octets de façon lisible (Mo à une décimale). */
function taille(octets) {
  if (typeof octets !== 'number' || octets <= 0) return '';
  const mo = octets / (1024 * 1024);
  return mo >= 1 ? `${mo.toFixed(1)} Mo` : `${Math.round(octets / 1024)} Ko`;
}

/** Échappe le texte destiné à être injecté en HTML. */
function esc(s) {
  return String(s).replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
  ));
}

function rendreErreur(message) {
  const zone = document.getElementById('downloads');
  zone.className = '';
  zone.innerHTML = `
    <div class="note note-err">
      <strong>Liste des versions indisponible</strong>
      <p>
        ${esc(message)} — les téléchargements restent accessibles directement
        sur GitHub : <a href="${RELEASES_URL}" rel="noopener">${RELEASES_URL}</a>
      </p>
    </div>`;
}

function rendreRelease(release) {
  const version = release.tag_name || release.name || '';
  const assets = Array.isArray(release.assets) ? release.assets : [];

  const badge = document.getElementById('badge-version');
  const date = release.published_at
    ? new Date(release.published_at).toLocaleDateString('fr-FR',
        { year: 'numeric', month: 'long', day: 'numeric' })
    : null;
  badge.textContent = date
    ? `Dernière version : ${version} — ${date}`
    : `Dernière version : ${version}`;

  const cartes = PLATEFORMES.map((p) => {
    const asset = assets.find((a) => p.match(a.name || ''));
    if (!asset) {
      // Un paquet absent se dit. Une carte silencieusement manquante
      // laisserait croire que la plateforme n'est pas supportée.
      return `
        <article class="card dl">
          <div class="dl-os"><span class="ico">${p.ico}</span>${esc(p.nom)}</div>
          <p class="dl-hint muted">Pas de paquet ${esc(p.nom)} dans ${esc(version)}.</p>
          <a class="btn btn-ghost" href="${RELEASES_URL}" rel="noopener">Voir les autres versions</a>
        </article>`;
    }
    return `
      <article class="card dl">
        <div class="dl-os"><span class="ico">${p.ico}</span>${esc(p.nom)}</div>
        <div class="dl-meta">${esc(p.detail)} · ${esc(taille(asset.size))}</div>
        <a class="btn btn-primary" href="${esc(asset.browser_download_url)}"
           download>Télécharger ${esc(version)}</a>
        <p class="dl-hint">${esc(p.hint)}</p>
      </article>`;
  });

  const zone = document.getElementById('downloads');
  zone.className = 'grid grid-3';
  zone.innerHTML = cartes.join('');

  // Les sommes de contrôle : discrètes, mais présentes. Un binaire qu'on ne
  // peut pas vérifier n'est pas un binaire de confiance.
  const sha = assets.find((a) => /SHA256.*\.txt$/i.test(a.name || ''));
  if (sha) {
    document.getElementById('checksums').innerHTML =
      `Vérifier l'intégrité : <a href="${esc(sha.browser_download_url)}" rel="noopener">`
      + `${esc(sha.name)}</a> · <span class="mono">sha256sum -c ${esc(sha.name)}</span>`;
  }
}

async function charger() {
  try {
    const reponse = await fetch('/api/releases', { headers: { Accept: 'application/json' } });
    if (!reponse.ok) throw new Error(`le miroir a répondu ${reponse.status}`);

    const data = await reponse.json();
    // L'API renvoie une liste ; on prend la première version publiée.
    const liste = Array.isArray(data) ? data : [data];
    const release = liste.find((r) => r && !r.draft && !r.prerelease) || liste[0];
    if (!release) throw new Error('aucune version publiée');

    rendreRelease(release);
  } catch (err) {
    rendreErreur(err && err.message ? err.message : 'erreur inconnue');
    document.getElementById('badge-version').textContent = 'Versions sur GitHub';
  }
}

charger();
