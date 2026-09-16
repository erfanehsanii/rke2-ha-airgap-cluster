#!/usr/bin/env bash
set -Eeuo pipefail

snapshot=${1:-}
[[ -n "$snapshot" && -f "$snapshot" ]] || { printf 'Usage: %s SNAPSHOT_FILE\n' "$0" >&2; exit 2; }
[[ -s "$snapshot" ]] || { printf 'Snapshot is empty\n' >&2; exit 1; }
stat --printf='path=%n\nsize=%s\nmode=%a\nmodified=%y\n' "$snapshot"
sha256sum "$snapshot"
printf 'Structural checks passed. A checksum does not prove recoverability; perform an isolated restore drill.\n'
