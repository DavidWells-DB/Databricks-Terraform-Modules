#!/usr/bin/env bash
# Enforces Rule 2.6.1: cloud variation is structural (separate module trees), never a runtime toggle.
# Fails if any .tf file uses a scalar variable named "cloud" or branches on var.cloud at runtime.
set -euo pipefail

ERRORS=0

if grep -rn --include="*.tf" 'variable[[:space:]]*"cloud"' .; then
  echo ""
  echo "ERROR: Found scalar variable \"cloud\"."
  echo "       Cloud variation must be expressed structurally (separate module directories per cloud),"
  echo "       not as a runtime string input. See docs/DATABRICKS_RULES.md Rule 1.2."
  ERRORS=$((ERRORS + 1))
fi

if grep -rn --include="*.tf" 'var\.cloud[[:space:]]*==' .; then
  echo ""
  echo "ERROR: Found var.cloud == comparison."
  echo "       Cloud variation must be expressed structurally (separate module directories per cloud),"
  echo "       not as a runtime toggle. See docs/DATABRICKS_RULES.md Rule 1.2."
  ERRORS=$((ERRORS + 1))
fi

exit "$ERRORS"
