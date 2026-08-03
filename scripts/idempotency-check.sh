#!/usr/bin/env bash
# Idempotency gate — the check that would have caught E11.
#
# E11 was a perpetual-replacement bug: the module planned clean the first time but forced
# a replacement on every subsequent plan (violating no-op-reapply, TERRAFORM_RULES Rule 1.3).
# Plan-only and single-apply tests both passed; only a *second* plan revealed it.
#
# `terraform test` (1.15) has no native "assert no changes", so this enforces it directly:
#   1. terraform apply the module's examples/basic (the canonical fixture, Rule 4.4);
#   2. terraform plan -detailed-exitcode  → exit 0 = no changes (PASS), 2 = drift (FAIL);
#   3. terraform destroy (always, even on failure) to leave no orphans.
#
# Usage: idempotency-check.sh <module-dir>
# Requires the same cloud + Databricks credentials as the integration tests, plus a
# populated terraform.tfvars (or TF_VAR_* env) for the example's required inputs.

set -euo pipefail

MODULE_DIR="${1:?usage: idempotency-check.sh <module-dir>}"
EXAMPLE_DIR="${MODULE_DIR%/}/examples/basic"

if [ ! -d "${EXAMPLE_DIR}" ]; then
  echo "No ${EXAMPLE_DIR} — skipping idempotency gate (module has no basic example)."
  exit 0
fi

cd "${EXAMPLE_DIR}"

# terraform.tfvars for the example must be provided out-of-band (CI writes it from
# secrets, or a *.auto.tfvars is committed). Bail clearly if required inputs are missing
# rather than emitting a confusing plan error.
cleanup() {
  echo "::group::destroy (cleanup)"
  terraform destroy -auto-approve -input=false || echo "WARNING: destroy failed — check for orphaned resources."
  echo "::endgroup::"
}
trap cleanup EXIT

echo "::group::init"
terraform init -backend=false
echo "::endgroup::"

echo "::group::apply"
terraform apply -auto-approve -input=false
echo "::endgroup::"

echo "::group::idempotency re-plan (-detailed-exitcode)"
set +e
terraform plan -detailed-exitcode -input=false
code=$?
set -e
echo "::endgroup::"

case "${code}" in
  0)
    echo "PASS: second plan shows no changes — module is idempotent."
    ;;
  2)
    echo "FAIL: second plan shows changes — module is NOT idempotent (E11-class regression)." >&2
    echo "      A clean re-apply must be a no-op (TERRAFORM_RULES Rule 1.3)." >&2
    exit 1
    ;;
  *)
    echo "ERROR: terraform plan failed with exit code ${code}." >&2
    exit "${code}"
    ;;
esac
