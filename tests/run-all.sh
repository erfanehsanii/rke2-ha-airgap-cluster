#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
"$ROOT_DIR/tests/validate-shell.sh"
"$ROOT_DIR/tests/validate-yaml.sh"
"$ROOT_DIR/tests/validate-placeholders.sh"
"$ROOT_DIR/tests/validate-links.sh"
"$ROOT_DIR/tests/validate-mermaid.sh"
"$ROOT_DIR/scripts/security-scan.sh"
