#!/usr/bin/env bash
#
# Cubox — installation sur Arch Linux et dérivées.
#
#   curl -fsSLO https://cubox.yabox.wasabout.net/install-arch.sh
#   bash install-arch.sh
#
# Met en place le dépôt pacman signé de Cubox, puis l'installe. Ensuite,
# `pacman -Syu` (ou `yay -Syu`) le met à jour comme n'importe quel paquet,
# sans recompiler.
#
# CE QU'IL DEMANDE, ET CE QU'IL NE DEMANDE PAS
# Une seule question est posée : celle qui engage vraiment quelque chose —
# accorder ta confiance à une clé de signature, ce qui revient à autoriser
# quelqu'un à installer des logiciels en root chez toi.
#
# Le reste (télécharger un fichier, ajouter une ligne à pacman.conf, lancer
# pacman -S) sont les gestes ordinaires d'une installation : ils sont
# AFFICHÉS au fur et à mesure, mais pas soumis à validation. Multiplier les
# « continuer ? » n'ajoute aucune sécurité, ça apprend juste à taper « o »
# sans lire — y compris le jour où la question compte.
#
# Tout retirer : bash install-arch.sh --desinstaller
set -euo pipefail

# CUBOX_SITE n'existe que pour pouvoir rejouer ce script contre un dépôt local
# en intégration continue. Un script d'installation qu'on ne peut pas tester
# est un script qu'on découvre cassé chez l'utilisateur.
readonly SITE="${CUBOX_SITE:-https://cubox.yabox.wasabout.net}"
readonly DEPOT="$SITE/arch"
readonly CLE_URL="$DEPOT/cubox-signing-key.asc"
readonly CONF="/etc/pacman.conf"

# ── Affichage ────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  G=$'\033[32m'; B=$'\033[36m'; J=$'\033[33m'; R=$'\033[31m'; GRIS=$'\033[90m'; Z=$'\033[0m'
else
  G=''; B=''; J=''; R=''; GRIS=''; Z=''
fi
etape() { printf '\n%s==> %s%s\n' "$B" "$*" "$Z"; }
ok()    { printf '%s  ✔ %s%s\n' "$G" "$*" "$Z"; }
info()  { printf '    %s\n' "$*"; }
err()   { printf '%s  ✘ %s%s\n' "$R" "$*" "$Z" >&2; }

# Toute commande privilégiée est AFFICHÉE avant d'être lancée. Sans ça,
# « le script s'occupe de tout » signifie « tu ne sais pas ce qui tourne en
# root chez toi ».
run_sudo() {
  printf '%s    $ sudo %s%s\n' "$GRIS" "$*" "$Z"
  sudo "$@"
}

demander() {  # la question, quand il y en a une
  local reponse
  printf '\n%s  ? %s%s [o/N] ' "$J" "$1" "$Z"
  read -r reponse </dev/tty || return 1
  [[ "$reponse" =~ ^[oOyY]$ ]]
}

# ── Garde-fous ───────────────────────────────────────────────────────────────
# On teste /dev/tty, PAS l'entrée standard : la question est posée sur le
# terminal (`read </dev/tty`), donc c'est lui qui doit exister. Tester `-t 0`
# refuserait à tort un `bash install-arch.sh < /dev/null` parfaitement valide,
# et — piège inverse — laisserait passer un `curl | bash` si stdin venait à
# être un terminal. C'est la disponibilité du terminal qui compte.
if ! : >/dev/tty 2>/dev/null; then
  err "Aucun terminal disponible pour te poser la question de confiance."
  err "Télécharge le script puis lance-le, plutôt que de le passer dans un tube :"
  err "    curl -fsSLO $SITE/install-arch.sh && bash install-arch.sh"
  err "Un « curl | bash » s'exécute avant que tu aies pu le lire."
  exit 1
fi

if [[ $EUID -eq 0 ]]; then
  err "Ne lance pas ce script en root."
  err "Il appellera sudo lui-même, seulement là où c'est nécessaire, et"
  err "affichera chaque commande avant de la lancer."
  exit 1
fi

command -v pacman >/dev/null 2>&1 || {
  err "pacman introuvable : ce script est pour Arch Linux et ses dérivées."
  err "Sur une autre distribution, prends l'archive .tar.gz sur $SITE"
  exit 1
}
for outil in curl gpg sudo; do
  command -v "$outil" >/dev/null 2>&1 || { err "Outil manquant : $outil"; exit 1; }
done

# ── Désinstallation ──────────────────────────────────────────────────────────
# Question conservée : détruire quelque chose n'est pas un geste ordinaire.
if [[ "${1:-}" == "--desinstaller" ]]; then
  etape "Désinstallation"
  info "Sera retiré : le paquet cubox, la section [cubox] de $CONF,"
  info "et la clé de signature du trousseau de pacman."
  info "Tes mondes et ta configuration ne sont pas touchés."
  demander "Confirmer ?" || { echo; err "Abandon, rien n'a été modifié."; exit 1; }

  if pacman -Qi cubox >/dev/null 2>&1; then run_sudo pacman -R --noconfirm cubox; else info "paquet non installé"; fi
  if grep -qF '[cubox]' "$CONF"; then
    run_sudo cp "$CONF" "$CONF.avant-cubox"
    run_sudo sed -i '/^\[cubox\]$/,/^Server *=.*cubox.*$/d' "$CONF"
    ok "section retirée (sauvegarde : $CONF.avant-cubox)"
  fi
  empreinte="$(sudo pacman-key --list-keys 2>/dev/null | grep -B1 -i 'Cubox CI' | grep -oE '[A-F0-9]{40}' | head -n1 || true)"
  [[ -n "$empreinte" ]] && run_sudo pacman-key --delete "$empreinte" || true
  echo; ok "Terminé."
  exit 0
fi

# ── Présentation ─────────────────────────────────────────────────────────────
cat <<PRESENTATION

  ${B}Cubox${Z} — launcher Minecraft hors-ligne
  ${GRIS}$SITE${Z}

  Installation du dépôt pacman signé, puis de Cubox.
  Une seule question te sera posée : celle qui engage ta confiance.

PRESENTATION

# ── 1. La clé ────────────────────────────────────────────────────────────────
etape "1/4  Clé de signature"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
info "téléchargement : $CLE_URL"
curl -fsSL "$CLE_URL" -o "$tmp/cle.asc" || { err "Téléchargement impossible — le site est-il joignable ?"; exit 1; }
ok "clé récupérée ($(wc -c < "$tmp/cle.asc") octets)"

# GNUPGHOME dédié, et `|| true` : on ne lit que ce fichier, jamais le
# trousseau personnel de l'utilisateur — dont on n'a pas à dépendre, et qu'on
# ne doit surtout pas toucher. Sans le `|| true`, `set -e` ferait sortir le
# script EN SILENCE si gpg échouait, avant même le message d'erreur ci-dessous.
# (Constaté en test : le script s'arrêtait après « clé récupérée », sans rien dire.)
mkdir -p "$tmp/gnupg"; chmod 700 "$tmp/gnupg"
lire_cle() { GNUPGHOME="$tmp/gnupg" gpg --show-keys "$@" 2>/dev/null || true; }
EMPREINTE="$(lire_cle --with-colons "$tmp/cle.asc" | awk -F: '/^fpr:/ {print $10; exit}')"
if [[ -z "$EMPREINTE" ]]; then
  err "Fichier de clé illisible — le téléchargement a-t-il abouti ?"
  err "Reçu : $(head -c 60 "$tmp/cle.asc" | tr -d '\n')…"
  exit 1
fi
echo
lire_cle --with-fingerprint "$tmp/cle.asc" | sed 's/^/    /' 

# ── LA question ──────────────────────────────────────────────────────────────
cat <<CONFIANCE

  ${J}Empreinte de la clé :${Z}

      $EMPREINTE

  ${J}Ce que tu vas autoriser :${Z} tout paquet signé par cette clé pourra être
  installé sur ta machine ${J}en root${Z}, aujourd'hui et lors des mises à jour.

  ${GRIS}Compare cette empreinte à celle publiée sur $SITE.
  Ce contrôle n'est pas une formalité : la clé vient du même serveur que les
  paquets. Si ce serveur était compromis, il servirait SA clé et SES paquets,
  et tout paraîtrait normal. La comparer à une source obtenue autrement est
  la seule chose qui casse ce cercle.${Z}
CONFIANCE

demander "Faire confiance à cette clé ?" || { echo; err "Abandon. Rien n'a été modifié."; exit 1; }

# ── 2 à 4 : gestes ordinaires, affichés mais non soumis à validation ─────────
etape "2/4  Ajout au trousseau de pacman"
sudo pacman-key --init >/dev/null 2>&1 || true
run_sudo pacman-key --add "$tmp/cle.asc"
run_sudo pacman-key --lsign-key "$EMPREINTE"
ok "clé installée et approuvée"

etape "3/4  Déclaration du dépôt"
if grep -qF '[cubox]' "$CONF"; then
  ok "déjà déclaré dans $CONF — inchangé"
else
  info "ajout à la fin de $CONF :"
  printf '%s      [cubox]\n      SigLevel = Required DatabaseOptional\n      Server = %s%s\n' "$GRIS" "$DEPOT" "$Z"
  info "SigLevel = Required : pacman refusera tout paquet non signé par la clé"
  info "ci-dessus — même réglage que les dépôts officiels d'Arch."
  run_sudo cp "$CONF" "$CONF.avant-cubox"
  printf '\n[cubox]\nSigLevel = Required DatabaseOptional\nServer = %s\n' "$DEPOT" \
    | sudo tee -a "$CONF" >/dev/null
  ok "dépôt ajouté (sauvegarde : $CONF.avant-cubox)"
fi

etape "4/5  Installation"
info "la signature est vérifiée ici : si elle ne correspond pas, pacman s'arrête"
run_sudo pacman -Sy
run_sudo pacman -S --needed --noconfirm cubox

# ── 5. Ménage ────────────────────────────────────────────────────────────────
# Une installation qui laisse traîner ses outils derrière elle n'est pas finie.
etape "5/5  Ménage"

# a) Le paquet téléchargé dans le cache de pacman. Il est re-téléchargeable à
#    tout moment depuis le dépôt : le garder n'apporte rien ici, contrairement
#    à un paquet des dépôts officiels qu'on voudrait pouvoir réinstaller
#    hors-ligne.
caches=$(sudo find /var/cache/pacman/pkg -maxdepth 1 -name 'cubox-*.pkg.tar.zst*' 2>/dev/null | wc -l)
if [[ "$caches" -gt 0 ]]; then
  run_sudo find /var/cache/pacman/pkg -maxdepth 1 -name 'cubox-*.pkg.tar.zst*' -delete
  ok "cache pacman nettoyé ($caches fichier(s))"
fi

# b) La sauvegarde de pacman.conf. On ne la retire QU'APRÈS avoir constaté que
#    pacman fonctionne toujours — c'est ce qu'elle servait à garantir, et une
#    sauvegarde qu'on efface avant d'avoir vérifié ne protège de rien.
if [[ -f "$CONF.avant-cubox" ]] && pacman -Sl cubox >/dev/null 2>&1; then
  run_sudo rm -f "$CONF.avant-cubox"
  ok "sauvegarde de pacman.conf retirée (pacman fonctionne, elle a fait son travail)"
fi

# c) Les restes d'une installation précédente par makepkg. Ce sont des dossiers
#    qui appartiennent à l'utilisateur : on DEMANDE avant d'y toucher, c'est son
#    dépôt de travail, pas le nôtre.
restes=()
while IFS= read -r d; do restes+=("$d"); done < <(
  find "$HOME" -maxdepth 4 -type d -path '*/packaging/aur' 2>/dev/null)
for aur in "${restes[@]:-}"; do
  [[ -n "$aur" ]] || continue
  vieux=$(find "$aur" -maxdepth 1 \( -name 'src' -o -name 'pkg' -o -name '*.pkg.tar.zst' \) 2>/dev/null | wc -l)
  [[ "$vieux" -gt 0 ]] || continue
  echo
  info "restes d'une compilation précédente dans : $aur"
  find "$aur" -maxdepth 1 \( -name 'src' -o -name 'pkg' -o -name '*.pkg.tar.zst' \) \
    -exec du -sh {} + 2>/dev/null | sed 's/^/      /'
  if demander "Supprimer ces fichiers de compilation ?"; then
    find "$aur" -maxdepth 1 \( -name 'src' -o -name 'pkg' -o -name '*.pkg.tar.zst' \) \
      -exec rm -rf {} + 2>/dev/null || true
    ok "restes de compilation supprimés"
  else
    info "conservés"
  fi
done

# d) Le script lui-même. Il a fini son travail ; le laisser traîner, c'est
#    inviter à le relancer un jour avec une empreinte périmée.
MOI="$(readlink -f "$0" 2>/dev/null || true)"

echo
ok "Cubox $(pacman -Q cubox | awk '{print $2}') est installé."

# La preuve que l'objectif est atteint : tant que cubox apparaissait dans
# `pacman -Qm` (paquets étrangers), yay allait le chercher sur l'AUR — où il
# n'existe pas — et le laissait figé sans rien dire.
if pacman -Qm 2>/dev/null | grep -q '^cubox '; then
  echo
  err "cubox est encore vu comme un paquet ÉTRANGER : yay ne le mettra pas à jour."
  err "Relance : sudo pacman -S cubox   (pour le réinstaller depuis le dépôt)"
else
  ok "cubox vient bien du dépôt [cubox] — yay -Syu le suivra"
fi

cat <<FIN

    Lancer        : la commande ${B}cubox${Z}, ou l'entrée « Cubox » de ton menu
    Mettre à jour : ${B}yay -Syu${Z} — comme n'importe quel paquet, sans recompiler
    Tout retirer  : ${B}sudo pacman -R cubox${Z} puis retirer [cubox] de $CONF

    Tes mondes et ta configuration vivent dans ~/.local/share/cubox
    et ne sont jamais touchés par une mise à jour.

    Il ne reste sur ta machine que le logiciel et le dépôt qui le met à jour.

FIN

if [[ -n "$MOI" && -f "$MOI" ]]; then
  rm -f "$MOI" && printf '%s  ✔ %s%s\n' "$G" "script d'installation supprimé ($MOI)" "$Z"
fi
