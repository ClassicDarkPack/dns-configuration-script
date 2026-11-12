#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
script="./set-dns.sh"
bash -n "$script"
[[ "$(bash "$script" --version)" == "2.0.0" ]]
bash "$script" --help | grep -q -- '--restore'
bash "$script" --primary 1.1.1.1 --secondary 1.0.0.1 --dry-run | grep -q 'no changes made'
if bash "$script" --primary 999.1.1.1 --secondary 1.0.0.1 --dry-run >/dev/null 2>&1; then
  echo "Invalid IPv4 accepted" >&2; exit 1
fi
if bash "$script" --primary 1.1.1.1 --secondary 1.1.1.1 --dry-run >/dev/null 2>&1; then
  echo "Duplicate resolvers accepted" >&2; exit 1
fi
if bash "$script" --primary 1.1.1.1 --secondary 1.0.0.1 --unexpected >/dev/null 2>&1; then
  echo "Unknown argument accepted" >&2; exit 1
fi
echo 'CLI checks passed (no host DNS settings changed).'
