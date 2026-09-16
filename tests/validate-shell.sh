#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"
while IFS= read -r -d '' file; do bash -n "$file"; printf 'PASS %s\n' "$file"; done < <(find scripts tests -type f -name '*.sh' -print0)
if command -v shellcheck >/dev/null 2>&1; then
  find scripts tests -type f -name '*.sh' -print0 | xargs -0 shellcheck -x
else
  printf 'SKIP ShellCheck is not installed\n'
fi
