# Terraform Module Rules — General

Working document. General Terraform rules, applicable to any modular framework regardless of provider.

Source material: [compass_artifact_wf-4d0c4a77-ced6-484c-ac8b-c6a824ab5ed2_text_markdown.md](./compass_artifact_wf-4d0c4a77-ced6-484c-ac8b-c6a824ab5ed2_text_markdown.md)

Databricks-specific extensions live in [DATABRICKS_RULES.md](./DATABRICKS_RULES.md).

Each rule cites its source line in the compass document in parentheses.

---

## 1. Identify

How we decide what becomes a module and what doesn't.

**1.1 — Abstraction test.** A new module is justified only if it describes "a new concept in your architecture that is constructed from resource types offered by providers" (line 10). If the proposed module name is the same as the resource type inside it, do NOT create the module — use the resource directly (lines 10, 146).

**1.2 — Reuse-or-cohesion test.** A new module is justified only when one of the following is true:
- The same group of resources will be configured together in two or more places.
- The resources form a single function ("networking, compute, IAM" — line 20) that always belongs together, and treating them as one unit raises the level of abstraction (Rule 1.1).

If neither holds, the resources stay in the root composition.

**1.3 — Start minimal.** "Start with a minimal viable module that solves a concrete use case and extend it through small, incremental changes" (line 22). The first version of any module covers only what the first known use case needs.

**1.4 — Coupling drives splits, not anticipation.** Split a module only when "a change in one module unexpectedly alters the state of many others during a Terraform plan" (line 20) OR when a concrete second use case needs a piece independently. Anticipated coupling is not a reason to split.

**1.5 — Non-modules.** Do NOT make a module for: a single resource with the same name as its resource type (line 146), a passthrough that adds only tags, anything used in exactly one place where the resource isn't intrinsically reusable.

---

## 2. Structure

How a module is laid out.

**2.1 — Standard file layout (mandatory).** Every module has at minimum (line 26):
```
<module>/
  main.tf       # primary resources + nested module calls
  variables.tf  # typed, described, optionally validated
  outputs.tf    # described
  versions.tf   # required_version + required_providers (lower-bound only)
  README.md     # purpose + link to example
  examples/     # at least one example
```
Optional: `locals.tf`, `data.tf`, `moved.tf` (during refactor), `tests/`.

**2.2 — Flat tree.** No nested modules unless three or more callers share the sub-piece (lines 10, 18). Composition lives in the root, not inside the module.

**2.3 — Provider config is forbidden in modules.** `provider {}` blocks live in root compositions only (TL;DR line 4). Modules declare `required_providers` only (line 51).

**2.4 — Naming.**
- `snake_case` for variables, outputs, locals, resource identifiers (line 45).
- Sole resource of a type → `this` (line 45).
- Don't repeat the resource type in the resource name (line 45).
- Module directory name matches the abstraction, not the resource type (line 10).

**2.5 — Variables.**
- Every variable: `type` + `description` (line 36).
- Required variables: `nullable = false` (line 38).
- Secrets: `sensitive = true`, no default (line 39). Use `ephemeral = true` if the value should never touch state (line 40).
- Optional features: `default = null` + `nullable = true`; null means "skip" (line 38).
- Complex inputs: `object({...})` with `optional()` for additive evolution; provide defaults at every nesting level (line 41).
- Validation: do not add `validation` blocks for constraints the type system already enforces (e.g., asserting a string is a string — line 37). DO validate genuine input constraints the type system cannot express: length bounds, allowed character sets, enumerated values, mutual exclusivity, format patterns (regex). Validation blocks fail at plan time, which is preferable to apply-time errors.

**2.6 — Outputs.**
- Every output: `description` (line 36).
- Proactively expose attributes a plausible caller might need (line 43).
- Do not toggle features through stringly-typed inputs that fail at plan time (line 43).

**2.7 — Pure dependency inversion.** Modules accept dependencies as inputs (lines 22, 73). They do NOT detect, look up, or create their own dependencies. They do NOT branch on "create if null" inside the module — that's two jobs in one module, which violates single-responsibility. The decision of whether to create a dependency or adopt an existing one is a root-composition concern: the root either calls a creation module or uses a `data` source, then passes the resulting ID/object as an input to the consuming module.

---

## 3. Build

How a module is implemented.

**3.1 — One PR, one logical change.** PRs introducing or changing a module are scoped to a single logical change. Reviewers reject compound PRs.

**3.2 — `for_each` is the default; `count` is the exception** (lines 117, 146).
- `for_each` for any resource set where instances have identity.
- `count` only for genuinely identical instances OR conditional creation (`count = var.enabled ? 1 : 0`).

**3.3 — No provisioners** (line 120). `local-exec`/`remote-exec` are a last resort.

**3.4 — No hardcoded values** (line 116). Values that vary across calls become variables. Build strings via `jsonencode`/`yamlencode`/`templatefile`, not concatenation.

**3.5 — Implicit dependencies preferred** (line 118). Let Terraform infer order via natural references; use `depends_on` only when no reference exists.

**3.6 — `versions.tf` is mandatory in every child module** (line 51). Declare `required_version` (Terraform lower bound) and `required_providers` (per-provider lower bound). See Rule 6.1 for the lower-bound vs. tight-pin distinction between child modules and root compositions.

**3.7 — Every module ships at least one example** under `examples/`, with its own README. Tests are written against examples, not against the module directly (line 30).

**3.8 — README content.** Module purpose, what it abstracts, when to use / when not to. Inputs/outputs are generated by `terraform-docs` (line 28) — do not hand-maintain those tables.

---

## 4. Test

How a module is validated.

**4.1 — Static gates run on every change** (line 87): `terraform fmt -check`, `terraform validate`, TFLint, a security scanner (Checkov or tfsec).

**4.2 — Native `terraform test` is the test framework** (line 89). Test files: `*.tftest.hcl` in the module's `tests/` subdir.

**4.3 — Plan-command tests for logic.** `command = plan` + `mock_provider` (Terraform 1.7+, line 89) validates input handling, conditional logic, computed names, validation blocks. Runs without credentials.

**4.4 — Apply-command tests for examples.** `command = apply` against the module's examples verifies real provisioning. Credential-gated; typically nightly or label-gated on PRs (line 89). The example IS the fixture.

**4.5 — Test realistic patterns, not combinatorial** (line 93). "Do not attempt to test every input combination; test realistic usage patterns."

**4.6 — Modules are not the security boundary** (line 93). Defensive compliance checks belong in policy-as-code applied at the blueprint or composition layer — not in module logic. Module-level `validation` blocks handle input correctness (length, format, allowed values); policy-as-code (OPA/Conftest) handles organizational posture across composed resources. A single module may be reused by blueprints with different postures (Quickstart, Production, Regulated); policies live with the blueprint, not the module.

---

## 5. Evolve

How modules change over time.

**5.1 — Semantic versioning is mandatory** (line 49).
- MAJOR: breaking change to inputs/outputs/behavior.
- MINOR: backward-compatible additions or deprecations.
- PATCH: backward-compatible fixes.

Modules are the **producer** in the pin relationship — consumers can only pin a version that modules have already tagged. Tagging is therefore a release gate, not a formality. Consequences:
- Every consumable change is published as an immutable semver tag (e.g. `aws-account-workspace/v1.2.0`).
- A published tag is never force-moved. If a tag was wrong, cut a new one.
- `main` is the integration branch, not a consumption target. Root compositions pin a tag, not `?ref=main`.

**5.2 — Each module has its own version.** Tag releases per module (e.g. `<module>/vX.Y.Z`). Each module has its own `CHANGELOG.md` (line 49).

**5.3 — Defaults are not free to change** (line 55). Changing a default is technically backward-compatible to Terraform but can alter live infrastructure on the next apply. Treat default changes as MAJOR unless the new default is provably no-op for existing callers.

**5.4 — Additive evolution preferred.**
- New optional inputs with safe defaults: MINOR.
- New outputs: MINOR.
- Renamed/removed inputs/outputs: MAJOR + deprecation period.

**5.5 — Deprecation pattern** (line 55).
- Mark old variable's `description` with `[DEPRECATED]` + migration target.
- Coalesce old and new during deprecation: `new_value = coalesce(var.new_input, var.old_input)`.
- Remove the old input only in the next MAJOR release.

**5.6 — Address changes go through `moved` blocks** (line 126).
- Renames, restructures, splits, count→for_each conversions all use `moved`.
- Blocks live in `moved.tf` (one manifest per module).
- Persist for at least one full apply cycle across every environment that consumed the prior version before removal.
- `terraform plan` MUST show a move, not destroy/create. PR review enforces this.

**5.7 — One refactor per branch** (line 130). Conflicting `moved` blocks on parallel branches cause confusing merge errors. Sequence refactors.

---

## 6. Maintain

How modules are kept healthy.

**6.1 — Lower bounds in child modules; tight pins in root** (line 51). Child: `>=`. Root: `~>` or exact. Never set upper bounds in child modules — they create unsatisfiable resolution.

**6.2 — `.terraform.lock.hcl` is committed in root compositions, not in modules** (line 51). Generate with `terraform providers lock -platform=...` for every platform CI and devs use.

**6.3 — Module sources are pinned by tag.** Root compositions reference modules by `?ref=<module>/vX.Y.Z` git tag, never by branch or HEAD.

**6.4 — Module ownership is explicit.** Every module has a named owner in CODEOWNERS. Unowned modules accumulate drift.

**6.5 — Provider upgrades on a cadence.** Provider bumps happen on a scheduled review, not opportunistically inside feature PRs.

**6.6 — Curation prevents proliferation** (line 119). Before creating a module that overlaps with an existing one, demonstrate why the existing one cannot be extended.

---

## 7. Deprecate

How modules retire.

**7.1 — Announce before removal.** A deprecated module gets a `DEPRECATED` notice at the top of its README and in the next MINOR release's CHANGELOG, with the replacement path and earliest removal version.

**7.2 — Deprecation period.** Minimum one MINOR release between announcement and removal. Longer if consumers haven't migrated.

**7.3 — Migration aid for non-trivial moves** (line 130). When deprecation involves real refactoring for consumers, ship either (a) `moved` blocks inside the deprecated module covering the rename to its replacement, or (b) a one-time migration module documented step-by-step.

**7.4 — Removal is a MAJOR.** Deleting a module from the catalog is a breaking change for any pinned consumer. The tag is preserved; only the source path/branch advances.

**7.5 — State unmanagement.** Use `removed` blocks (line 127) with `lifecycle { destroy = false }` to relinquish management of real objects without deleting them. Used when retiring a module whose resources transition to a different module or tool.
