#!/usr/bin/env bash
# gen-docs.sh — regenerate the GENERATED reference sections of the module READMEs.
#
# Each module's README carries a terraform-docs `inject` section between the
# BEGIN_TF_DOCS / END_TF_DOCS fences (configured in .terraform-docs.yml). Everything
# outside the fences is hand-written and preserved. CI runs this in --check mode so a
# drifted table fails the build (feedback-integration H3).
#
# IMPORTANT: the CI gate pins terraform-docs v0.20.0 — render locally with the SAME
# binary (the release-asset download; terraform-docs.io/dl/ serves HTML) or the table
# separators differ and every README drifts.
#
# Usage:
#   scripts/gen-docs.sh            # regenerate all module README fences
#   scripts/gen-docs.sh --check    # regenerate, fail if anything changed (CI gate)

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

if ! command -v terraform-docs >/dev/null 2>&1; then
  echo "ERROR: terraform-docs not found. Install from https://terraform-docs.io" >&2
  echo "       (use the pinned CI version, v0.20.0 — see the docs-gate job.)" >&2
  exit 2
fi

changed_any=0
for readme in "${REPO}"/*/README.md; do
  dir="$(dirname "${readme}")"
  [ -f "${dir}/main.tf" ] || continue   # only module directories
  grep -q "BEGIN_TF_DOCS" "${readme}" 2>/dev/null || { echo "  skip ${dir##*/} (no fence)"; continue; }
  terraform-docs -c "${REPO}/.terraform-docs.yml" "${dir}" >/dev/null 2>&1 \
    || { echo "  ERROR: terraform-docs failed on ${dir##*/}" >&2; changed_any=1; continue; }
  echo "  rendered ${dir##*/}/README.md"
done

if [ "${CHECK}" = "1" ]; then
  if ! git -C "${REPO}" diff --quiet -- '*/README.md'; then
    echo "" >&2
    echo "ERROR: generated module docs are stale. Run scripts/gen-docs.sh (with the pinned" >&2
    echo "terraform-docs v0.20.0) and commit." >&2
    git -C "${REPO}" --no-pager diff --stat -- '*/README.md' >&2
    exit 1
  fi
  echo "OK: generated docs are up to date."
fi
