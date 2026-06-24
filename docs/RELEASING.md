# Releasing Modules

This document describes how to cut an immutable, pinnable release for any module in this monorepo. Follow it exactly — released tags are immutable and downstream consumers depend on them.

---

## The three-tier contract

This repo is the **module tier** (producer). The tier above it — Components — pins specific module tags. The tier above that — Blueprints — pins component tags. The chain only works if module tags never move.

> Rule 5.1 / 6.3 summary: `main` is an integration branch, not a consumption target. Every consumable change must be published as an immutable semver tag. Consumers pin `?ref=<module>/vX.Y.Z`.

---

## Stability policy: v0.x vs v1.0.0

| Version range | Meaning | When to use |
|---|---|---|
| `v0.x.y` | Interface not yet stable; minor bumps may be breaking | Default for new modules. Use until the interface has been consumed in production for ≥ 1 release cycle and no further breaking changes are anticipated. |
| `v1.0.0+` | Interface is committed; breaking changes require a MAJOR bump | Cut only when you can assert that the variable/output surface won't change without a deliberate MAJOR. |

Most modules in this repo start at **v0.1.0**. Do not start at v1.0.0 unless you are certain the interface is stable.

---

## Pre-flight: required before any tag

A module is only tagable when all four checks are green:

```bash
# From the repo root
MODULE=aws-account-workspace  # replace with your module

terraform fmt -check -recursive "$MODULE"
terraform -chdir="$MODULE" init -backend=false
terraform -chdir="$MODULE" validate
terraform -chdir="$MODULE" test          # plan-command tests; no credentials needed
```

Fix any failures before proceeding. Do **not** skip the test step — plan-command tests with `mock_provider` run without credentials and must pass cleanly.

---

## Step-by-step: cutting a release

### 1. Make sure `main` is clean and green

```bash
git fetch origin
git status          # must be clean
git log --oneline origin/main..HEAD  # must be empty (or you're ahead; that's fine)
```

### 2. Run the pre-flight checks (above)

All four steps must pass. Record the result — the CHANGELOG entry should reflect what's actually in the release.

### 3. Update CHANGELOG.md

In `<module>/CHANGELOG.md`, convert the `[Unreleased]` section to the new version, then add a fresh empty `[Unreleased]` header above it:

```markdown
## [Unreleased]

## [0.1.0] - 2026-06-23

### Added
- …existing bullets…
```

Rules:
- Use ISO 8601 date (`YYYY-MM-DD`).
- Keep all existing bullet content intact — do not rewrite history.
- Commit the CHANGELOG update before tagging (the tag should point to the CHANGELOG-updated commit).

### 4. Commit the CHANGELOG

```bash
git add <module>/CHANGELOG.md
git commit -m "<module>: finalize CHANGELOG for v0.1.0"
```

### 5. Create the annotated tag

```bash
git tag -a <module>/v0.1.0 -m "<module> v0.1.0"
```

Tag naming rules:
- Format: `<module-directory-name>/vX.Y.Z` — the directory name exactly as it appears in the repo root.
- Always annotated (`-a`), never lightweight — annotated tags carry a tagger, timestamp, and message that lightweight tags lack.
- The prefix is the module's directory name. This prevents collision between modules in the monorepo.

### 6. Verify the tag before pushing

```bash
git show <module>/v0.1.0   # confirms annotated, message correct, points to CHANGELOG commit
```

Run `scripts/check-release-tag.sh <module>/v0.1.0` to verify the CHANGELOG entry matches.

### 7. Push the tag

```bash
git push origin <module>/v0.1.0
```

Push the tag **separately from branch pushes**. Never use `--tags` (it pushes all local tags indiscriminately). Push each tag explicitly by name.

### 8. Push the commit (if not already pushed)

```bash
git push origin main
```

---

## Tag immutability

**A published tag is never force-moved.** If a tag was cut at the wrong commit:

1. Cut a new patch release (e.g., `v0.1.1`) with the fix.
2. Document the issue in the new CHANGELOG entry.
3. Do NOT run `git tag -f` or `git push --force origin <tag>`.

The CI check (`scripts/check-release-tag.sh`) will fail if a tag's version does not match a CHANGELOG entry. GitHub branch-protection rules should be set to deny force-push to tag refs.

---

## Downstream consumption pattern

Consumers reference a module by tag:

```hcl
module "workspace" {
  source = "git::https://github.com/<org>/Databricks-Terraform-Modules//aws-account-workspace?ref=aws-account-workspace/v0.1.0"
}
```

Key points:
- The double slash (`//`) separates the repo URL from the subdirectory path (required by Terraform for monorepo sources).
- `?ref=` pins to the exact tag. Never use `?ref=main`.
- When a module is updated, bump its version and cut a new tag. Consumers update their `?ref=` pin explicitly.

---

## Bumping an existing module

| Change type | Version bump | Notes |
|---|---|---|
| Bug fix, no interface change | PATCH (`0.1.0 → 0.1.1`) | |
| New optional variable/output | MINOR (`0.1.0 → 0.2.0`) | |
| Removed/renamed variable, changed behavior | MAJOR (`0.1.0 → 1.0.0` or `0.2.0 → 0.3.0` while in 0.x) | In 0.x, MINOR bumps may be breaking — document clearly |
| Changing a default value | Treat as MAJOR per Rule 5.3 unless provably no-op |

---

## Terraform Registry readiness (current gap assessment)

The Terraform Registry requires one module per repo, named `terraform-<provider>-<name>`. This monorepo layout is **not directly compatible** with the Registry:

- The Registry resolves modules from the repo root — it cannot consume subdirectories without `?ref=` workarounds.
- Repo naming convention (`Databricks-Terraform-Modules`) does not match the required `terraform-<provider>-<name>` pattern.
- Publishing 51 modules from a monorepo would require splitting into 51 separate repos, each named appropriately.

**Action required (not yet taken):** If Registry publishing becomes a goal, plan a repo-split migration. Each module directory becomes its own `terraform-databricks-<module-name>` repo. The monorepo can remain as a development workspace with `moved` blocks bridging the transition. See `docs/SOVEREIGN_AUDIT.md` for the broader context on module interface stability before committing to that migration.

---

## Quick reference: release checklist

```
[ ] git fetch origin && git status (clean)
[ ] terraform fmt -check -recursive <module>
[ ] terraform -chdir=<module> init -backend=false
[ ] terraform -chdir=<module> validate
[ ] terraform -chdir=<module> test
[ ] Update <module>/CHANGELOG.md ([Unreleased] → [X.Y.Z] - YYYY-MM-DD)
[ ] git add <module>/CHANGELOG.md && git commit
[ ] git tag -a <module>/vX.Y.Z -m "<module> vX.Y.Z"
[ ] scripts/check-release-tag.sh <module>/vX.Y.Z
[ ] git push origin main
[ ] git push origin <module>/vX.Y.Z
```
