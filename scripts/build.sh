#!/usr/bin/env bash
# Build the documentation using MkDocs.
#
#   ./scripts/build.sh            # strict build
#   ./scripts/build.sh --no-strict
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

STRICT=1
for arg in "$@"; do
  case "$arg" in
    --no-strict) STRICT=0 ;;
    -h|--help)
      sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) die "unknown argument: $arg" ;;
  esac
done

cd "$DOCS_ROOT"

ensure_venv

args=(build)
[[ "$STRICT" -eq 1 ]] && args+=(--strict)

log "mkdocs ${args[*]}"
mkdocs "${args[@]}"
log "MkDocs output: ${DOCS_ROOT}/site/"
log "Build complete."
