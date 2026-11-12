#!/usr/bin/env bash
set -Eeuo pipefail
VERSION=2.0.0
DROPIN_DIR=/etc/systemd/resolved.conf.d
DROPIN_FILE="$DROPIN_DIR/90-dns-configuration-script.conf"
STATE_DIR=/var/lib/dns-configuration-script
STATE_FILE="$STATE_DIR/managed"
PRIMARY="" SECONDARY="" ACTION=apply DRY_RUN=false YES=false TMP=""

usage() {
cat <<'HELP'
DNS Configuration Script v2 (systemd-resolved only)
Usage:
  sudo bash set-dns.sh --primary 1.1.1.1 --secondary 1.0.0.1
  bash set-dns.sh --primary 1.1.1.1 --secondary 1.0.0.1 --dry-run
  bash set-dns.sh --status
  sudo bash set-dns.sh --restore
Options: --primary IP --secondary IP --yes --dry-run --status --restore --help --version
Does not modify /etc/resolv.conf or NetworkManager.
HELP
}
log(){ printf '[dns-config] %s\n' "$*"; }
die(){ printf '[dns-config] ERROR: %s\n' "$*" >&2; exit 1; }
cleanup(){ if [[ -n "$TMP" && -d "$TMP" ]]; then rm -rf -- "$TMP"; fi; }
trap cleanup EXIT

valid_ipv4(){
  local ip="$1" a b c d
  [[ "$ip" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || return 1
  IFS=. read -r a b c d <<< "$ip"
  ((10#$a <= 255 && 10#$b <= 255 && 10#$c <= 255 && 10#$d <= 255))
}
confirm(){
  local answer
  [[ "$YES" == true ]] && return 0
  [[ -t 0 ]] || die 'Non-interactive writes require --yes.'
  read -r -p 'Proceed? [y/N]: ' answer
  [[ "$answer" == y || "$answer" == Y ]] || die Cancelled
}
require_root(){ ((EUID == 0)) || die 'Use sudo for writes, or --dry-run/--status.'; }
require_system(){
  command -v systemctl >/dev/null 2>&1 || die 'systemctl is required.'
  systemctl is-active --quiet systemd-resolved || die 'systemd-resolved must be running; no changes made.'
}
status(){
  if [[ -f "$STATE_FILE" && -f "$DROPIN_FILE" && ! -L "$DROPIN_FILE" ]]; then
    log "Managed DNS override: $DROPIN_FILE"; cat -- "$DROPIN_FILE"
  elif [[ -e "$DROPIN_FILE" || -L "$DROPIN_FILE" ]]; then
    log 'Override exists but is not recognized as managed.'
  else log 'No managed DNS override.'; fi
  if command -v resolvectl >/dev/null 2>&1; then resolvectl dns || true; fi
}
apply(){
  if [[ -z "$PRIMARY" || -z "$SECONDARY" ]]; then
    if [[ -t 0 ]]; then
      [[ -n "$PRIMARY" ]] || read -r -p 'Primary IPv4 DNS: ' PRIMARY
      [[ -n "$SECONDARY" ]] || read -r -p 'Secondary IPv4 DNS: ' SECONDARY
    else die 'Provide --primary and --secondary for non-interactive use.'; fi
  fi
  valid_ipv4 "$PRIMARY" || die "Invalid primary IPv4 address: $PRIMARY"
  valid_ipv4 "$SECONDARY" || die "Invalid secondary IPv4 address: $SECONDARY"
  [[ "$PRIMARY" != "$SECONDARY" ]] || die 'DNS addresses must differ.'
  log "Proposed DNS: $PRIMARY $SECONDARY"
  log "Target: $DROPIN_FILE"
  if [[ "$DRY_RUN" == true ]]; then log 'Dry-run: no changes made.'; return; fi
  require_root; require_system
  [[ ! -L "$DROPIN_FILE" ]] || die 'Target is a symlink; refusing to overwrite.'
  [[ ! -e "$DROPIN_FILE" || -f "$STATE_FILE" ]] || die 'Unmanaged target exists; refusing to overwrite.'
  [[ ! -e "$STATE_FILE" || -f "$DROPIN_FILE" ]] || die 'Inconsistent management state.'
  confirm
  TMP="$(mktemp -d)"
  local previous=false
  if [[ -f "$DROPIN_FILE" ]]; then cp -- "$DROPIN_FILE" "$TMP/previous"; previous=true; fi
  printf '[Resolve]\nDNS=%s %s\n' "$PRIMARY" "$SECONDARY" > "$TMP/new"
  mkdir -p -- "$DROPIN_DIR"
  install -m 0644 -- "$TMP/new" "$DROPIN_FILE"
  if ! systemctl restart systemd-resolved; then
    log 'Restart failed; rolling back.'
    if [[ "$previous" == true ]]; then
      install -m 0644 -- "$TMP/previous" "$DROPIN_FILE"
    else rm -f -- "$DROPIN_FILE"; fi
    systemctl restart systemd-resolved || true
    die 'Update rolled back; verify resolver health.'
  fi
  mkdir -p -- "$STATE_DIR"
  printf 'managed by dns-configuration-script %s\n' "$VERSION" > "$STATE_FILE"
  log 'Applied. Verify effective DNS with: resolvectl status'
  log 'Interface-specific DNS and other drop-ins can affect effective DNS.'
}
restore(){
  if [[ "$DRY_RUN" == true ]]; then log "Dry-run: would remove managed $DROPIN_FILE and restart."; return; fi
  require_root; require_system
  [[ -f "$STATE_FILE" ]] || die 'No managed configuration to restore.'
  [[ -f "$DROPIN_FILE" && ! -L "$DROPIN_FILE" ]] || die 'Managed target missing or a symlink.'
  confirm
  TMP="$(mktemp -d)"
  cp -- "$DROPIN_FILE" "$TMP/previous"
  rm -- "$DROPIN_FILE"
  if ! systemctl restart systemd-resolved; then
    install -m 0644 -- "$TMP/previous" "$DROPIN_FILE"
    systemctl restart systemd-resolved || true
    die 'Restore failed; previous managed override restored.'
  fi
  rm -f -- "$STATE_FILE"
  log 'Managed override removed; prior resolver settings now apply.'
}
while (($#)); do
  case "$1" in
    --primary|--secondary)
      (($# >= 2)) || die "$1 requires a value"
      if [[ "$1" == --primary ]]; then PRIMARY="$2"; else SECONDARY="$2"; fi
      shift 2;;
    --dry-run) DRY_RUN=true; shift;;
    --yes) YES=true; shift;;
    --status) ACTION=status; shift;;
    --restore) ACTION=restore; shift;;
    --help|-h) usage; exit 0;;
    --version) echo "$VERSION"; exit 0;;
    *) die "Unknown option: $1";;
  esac
done
case "$ACTION" in
  apply) apply;;
  restore) restore;;
  status) status;;
esac
