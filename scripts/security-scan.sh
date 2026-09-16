#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"
command -v rg >/dev/null 2>&1 || { printf 'ERROR: ripgrep (rg) is required\n' >&2; exit 1; }
fail=0
scan() {
  local description=$1 pattern=$2
  printf '\n### %s\n' "$description"
  if rg -n -i --hidden --glob '!.git/**' --glob '!scripts/security-scan.sh' "$pattern" .; then fail=1; else printf 'No matches\n'; fi
}
scan "Private key markers" 'BEGIN [A-Z ]*PRIVATE KEY'
printf '\n### IPv4 addresses\n'
if rg -n --hidden --glob '!.git/**' --glob '!scripts/security-scan.sh' '(^|[^0-9])([0-9]{1,3}\.){3}[0-9]{1,3}([^0-9]|$)' . \
  | rg -v '0\.0\.0\.0|127\.0\.0\.1|192\.0\.2\.|198\.51\.100\.|203\.0\.113\.'; then
  fail=1
else
  printf 'No non-allowlisted matches\n'
fi
scan "Email addresses" '[[:alnum:]_.+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}'
scan "Credential assignments" '(password|passwd|token|api[_-]?key|secret)[[:space:]]*[:=][[:space:]]*[^<[:space:]]+'
if command -v gitleaks >/dev/null 2>&1; then gitleaks detect --source . --no-banner --redact || fail=1
else printf '\nGitleaks unavailable; built-in scans only.\n'; fi
exit "$fail"
