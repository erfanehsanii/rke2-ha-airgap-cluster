#!/usr/bin/env bash

set -Eeuo pipefail

log() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
require_root() { [[ ${EUID:-$(id -u)} -eq 0 ]] || die "run as root"; }
require_command() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"; }
require_file() { [[ -f "$1" ]] || die "required file not found: $1"; }

confirm_exact() {
  local expected=$1 prompt=$2 answer
  printf '%s\nType %s to continue: ' "$prompt" "$expected" >&2
  read -r answer
  [[ "$answer" == "$expected" ]] || die "confirmation did not match"
}
