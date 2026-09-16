#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"
if rg -n -i --hidden --glob '!.git/**' --glob '!tests/validate-placeholders.sh' \
  '(10\.[0-9]{1,3}(\.[0-9]{1,3}){2}|172\.(1[6-9]|2[0-9]|3[01])(\.[0-9]{1,3}){2}|192\.168(\.[0-9]{1,3}){2}|company[-_. ]?(internal|corp)|corp\.local)'; then
  printf 'Private network address or company-specific marker detected\n' >&2
  exit 1
fi
printf 'PASS no known production identifiers found\n'
