/* Statistiques de téléchargement, lues sur la même route relayée que la page
 * publique (`/api/releases`). Aucun appel supplémentaire, aucun jeton : le
 * compteur `download_count` est déjà dans la réponse de l'API GitHub.
 *
 * L'authentification n'est PAS faite ici. Elle est faite par Traefik, en
 * amont, via oauth2-proxy et le groupe Cloudox-Cubox (cf. Cloudox/infra,
 * tenants/cubox/ingress.yaml). Une vérification côté navigateur ne protégerait
 * rien : il suffirait de désactiver JavaScript.
 */

function esc(s) {
  return String(s).replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
  ));
}

function mo(octets) {
  return typeof octets === 'number' && octets > 0
    ? `${(octets / (1024 * 1024)).toFixed(1)} Mo`
    : '—';
}

function rendre(releases) {
  const zone = document.getElementById('stats');

  const total = releases.reduce(
    (n, r) => n + (r.assets || []).reduce((m, a) => m + (a.download_count || 0), 0), 0);

  const blocs = releases.map((r) => {
    const assets = (r.assets || []).slice()
      .sort((a, b) => (b.download_count || 0) - (a.download_count || 0));
    const sous_total = assets.reduce((n, a) => n + (a.download_count || 0), 0);
    const date = r.published_at
      ? new Date(r.published_at).toLocaleDateString('fr-FR',
          { year: 'numeric', month: 'long', day: 'numeric' })
      : '';
    const lignes = assets.map((a) => `
      <tr>
        <td class="mono">${esc(a.name)}</td>
        <td class="mono" style="text-align:right">${esc(mo(a.size))}</td>
        <td class="mono" style="text-align:right"><strong>${a.download_count || 0}</strong></td>
      </tr>`).join('');
    return `
      <article class="card">
        <h3>${esc(r.tag_name || r.name)} <span class="muted" style="font-weight:400;font-size:.9rem">· ${esc(date)}</span></h3>
        <p class="muted">${sous_total} téléchargement${sous_total > 1 ? 's' : ''}</p>
        <table style="width:100%;border-collapse:collapse;margin-top:.75rem;font-size:.9rem">
          <thead>
            <tr class="muted" style="text-align:left">
              <th style="padding-bottom:.4rem">Fichier</th>
              <th style="text-align:right">Taille</th>
              <th style="text-align:right">Téléch.</th>
            </tr>
          </thead>
          <tbody>${lignes}</tbody>
        </table>
      </article>`;
  });

  zone.innerHTML = `
    <div class="card">
      <h3 class="grad-text" style="font-size:2rem">${total}</h3>
      <p class="muted">téléchargements cumulés, toutes versions confondues</p>
    </div>
    ${blocs.join('')}`;
}

async function charger() {
  const zone = document.getElementById('stats');
  try {
    const r = await fetch('/api/releases', { headers: { Accept: 'application/json' } });
    if (!r.ok) throw new Error(`le miroir a répondu ${r.status}`);
    const data = await r.json();
    const liste = Array.isArray(data) ? data : [data];
    if (!liste.length) throw new Error('aucune version publiée');
    rendre(liste);
  } catch (err) {
    zone.innerHTML = `
      <div class="note note-err">
        <strong>Statistiques indisponibles</strong>
        <p>${esc(err && err.message ? err.message : 'erreur inconnue')}</p>
      </div>`;
  }
}

charger();
