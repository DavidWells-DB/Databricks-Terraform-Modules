# Terraform and Module Best Practices: A Reference Summary for a Modular Framework

## TL;DR
- HashiCorp's core guidance is to build flat, composable, single-responsibility modules that raise the level of abstraction, keep provider configuration in root modules only, and treat every configuration as a potential module from day one; avoid thin single-resource wrappers and deeply nested module trees.
- The framework should standardize on the standard module file layout, typed and validated inputs with documented outputs, semantic versioning with pinned providers via a lock file, isolated remote state per environment and per layer, and dependency inversion (pass dependencies in as inputs rather than fetching them inside modules).
- Quality gates are non-negotiable: fmt/validate plus static analysis (TFLint, Checkov/tfsec), native `terraform test` for logic, policy-as-code (Sentinel/OPA), and a plan-then-apply CI/CD pipeline with human approval, short-lived credentials, and scheduled drift detection.

## Key Findings

The single most important architectural principle from HashiCorp is module composition: build a flat tree of small, composable building-block modules assembled by a root module, rather than a deeply nested hierarchy. HashiCorp's "Creating Modules" documentation states that a good module "should raise the level of abstraction by describing a new concept in your architecture that is constructed from resource types offered by providers," and explicitly warns: "We do not recommend writing modules that are just thin wrappers around single other resource types. If you have trouble finding a name for your module that isn't the same as the main resource type inside it, that may be a sign that your module is not creating any new abstraction and so the module is adding unnecessary complexity."

For a workspace-deployment framework intended to generalize across resource types and vendors over time, the highest-leverage decisions are: (1) keep modules pure by accepting dependencies as inputs, (2) enforce a stable input/output interface contract that survives versioning, (3) isolate state to bound blast radius, and (4) wire layers together with explicit inputs or narrowly scoped remote-state reads rather than tight coupling.

## Details

### 1. Module design principles

A module is a container for resources used together that creates a lightweight abstraction, letting you describe infrastructure in terms of architecture rather than physical objects. The .tf files in the working directory form the root module; modules it calls are child modules. HashiCorp recommends keeping the module tree relatively flat and using composition as an alternative to deeply nested trees, because flat composition makes individual modules easier to reuse in different combinations.

Encapsulation and single responsibility are central. In HashiCorp's blog "How to write and rightsize Terraform modules," which summarizes Rene Schach's (Senior Cloud Consultant at shiftavenue) HashiDays 2025 talk, the guidance is that "Each module should perform one function well — such as networking, compute, or IAM," combining resources that always belong together. Over-modularization and under-modularization are both anti-patterns: overusing modules makes configuration harder to understand, while god modules that bundle unrelated domains inflate state and coupling. A practical coupling test from the same source: "If a change in one module unexpectedly alters the state of many others during a Terraform plan, that's a sign they are too tightly coupled."

Pure versus impure modules: HashiCorp's composition guidance recommends dependency inversion. Rather than a module detecting or creating its own dependencies (impure, environment-aware behavior), it should accept the object it needs as an input variable, typically modeled as an object type exposing only the attributes the module consumes. This keeps modules declarative, portable across environments, and free of hidden assumptions. The rightsizing guidance advises starting with a minimal viable module that solves a concrete use case and extending it "through small, incremental changes and pull requests."

### 2. Module structure and file layout

The standard module structure is the layout HashiCorp's tooling understands for documentation generation and registry indexing. The root module is the only required element. Recommended minimal files (recommended even if empty): main.tf (primary entrypoint; for complex modules, resource creation may be split into multiple files but nested module calls belong in the main file), variables.tf, outputs.tf. Common additions are versions.tf (Terraform and provider constraints), locals.tf, data.tf, and a LICENSE. Complex modules add a modules/ subdirectory for nested submodules and an examples/ subdirectory.

Documentation conventions: the root module and every nested module should have a README (README.md renders as markdown). The README does not need to manually document inputs and outputs because tooling such as terraform-docs generates that automatically. Every variable and output must carry a one- or two-sentence description. Nested submodules under modules/ with a README are considered consumable by external users; those without are internal-only (advisory, not enforced). Nested module calls within a package should use relative paths like ./modules/name so Terraform treats them as part of the same package, and submodules should ideally be composable by the caller rather than calling each other directly.

Examples directory: examples of using the module should live under examples/ at the repository root, each optionally with its own README. A strong convention (notably from Gruntwork) is that every module has a corresponding example, and tests are written against the examples rather than the modules directly, which keeps examples from going stale.

### 3. Inputs, outputs, and interfaces

The variable block supports type, default, description, sensitive, nullable, ephemeral, and validation, plus the optional() modifier inside object type constraints. Design guidance:

- Always set a type and a description on every variable, and a description on every output. Variables without a default are required.
- Validation: use validation blocks to fail fast on bad input at plan time. Do not over-validate things Terraform already enforces through types; reserve custom validators for genuine constraints (for example, enforcing at most one element in a single-element list).
- nullable: defaults to true. Set nullable = false on required inputs to reject null early and prevent confusing downstream errors. Use default = null with nullable = true to model genuinely optional features where null means "skip."
- sensitive: marks values redacted from CLI and UI output, but sensitive values are still written to state. Never set a default for secret inputs (so Terraform forces explicit provision), and mark them sensitive.
- ephemeral: omits the value from state and plan files entirely, ideal for transient credentials.
- Complex inputs: use an object with optional fields to gain plan-time validation and documentation while allowing future expansion without breaking changes; make as many fields optional as possible and provide defaults at every level of nesting. Be aware extra or misspelled fields in object inputs are silently ignored, which is a real trade-off versus separate scalar inputs.

Output design: expose any attribute a caller might plausibly need, since outputs are the only supported way for consumers to read information about resources a module manages. A well-known authoring discipline is to proactively output attributes so consumers never have to file an issue asking for one. Avoid leaky abstractions: do not toggle optional module features through arbitrary string or number inputs in ways that cause plan-time errors. Use null default values so that omitted inputs are not passed down to the underlying resource, letting the provider's own default apply.

Naming conventions (from the HashiCorp style guide and naming docs): use nouns for resource names; do not repeat the resource type in the resource name (the address already includes it); separate words with underscores; name the sole resource of a type "this" when no more descriptive name exists. Use underscores (not camelCase or hyphens) for variable, output, and resource identifiers. Registry-published modules must follow terraform-<PROVIDER>-<NAME>. Match upstream provider argument names for inputs to avoid ambiguity.

### 4. Versioning and dependency management

Modules should follow semantic versioning (MAJOR.MINOR.PATCH): major for breaking changes, minor for backward-compatible features and deprecations, patch for backward-compatible fixes. Place each shared module in its own version-controlled repository, use tag- or branch-based publishing, review changes via pull request, and publish a changelog per release.

Provider and Terraform version constraints: declare required_providers and required_version, ideally in versions.tf. The recommended split is that child modules declare only minimum/lower-bound constraints (for example, >= 5.0) to give consumers flexibility, while root modules (compositions) pin more tightly (~> for major/minor, or exact = pins) for reproducibility. Always commit the .terraform.lock.hcl lock file in root modules; it records exact provider versions and per-platform checksums. Generate it for all target platforms with terraform providers lock. Conflicting upper-bound constraints across modules can create unsatisfiable version requirements, so avoid upper bounds in shared child modules.

Module source references: registry (versioned, discoverable), git (supports ref pinning and shallow clones via depth), and local relative paths. Pin exact module versions in root modules for reproducibility; changing source or version requires terraform init (use -upgrade to move within constraints).

Breaking change management: changing a default value is subtle because it is technically backward-compatible to Terraform but can alter live infrastructure on the next apply (for example, flipping multi-AZ or encryption defaults). Prefer not changing defaults; if you must, do it in a major version and document it. Use deprecation patterns: keep an old variable with a deprecation note in its description and coalesce to the new one for a transition period, then remove it in a major release.

### 5. State management

Always use a remote backend for any team or production use. Remote state enables collaboration, supports state locking to prevent concurrent corrupting writes, allows encryption at rest and in transit, and supports versioning for rollback. Never commit state to version control and never manually edit state (use terraform state subcommands).

State isolation strategy is the most important blast-radius control. Maintain separate state per environment (dev/staging/prod) and per logical component or layer. Common mechanisms: distinct backend keys/prefixes per environment, distinct backends, or directory-based separation. Lock down production state backend permissions (read-only for most, write limited to the CI/CD pipeline and break-glass roles).

Workspaces versus directory-based separation: CLI workspaces let you reuse one configuration across similar environments with separate state, but for strong isolation and reduced blast radius, separate directories/backends per environment are generally more robust, especially when environments diverge architecturally. Workspaces are best when environments share identical architecture.

Avoid shared-state pitfalls: a monolithic single state tracking hundreds of resources slows operations and increases collaboration friction and risk; split it into smaller state files aligned to modules, teams, or domains.

### 6. Composition and layering patterns

A layered architecture separates concerns: a stable foundation layer (networking, accounts, identity), a platform layer, and application layers built on top. The foundation must be designed carefully up front because dependent layers make it expensive to recreate later. Gruntwork formalizes a related three-tier model: modules (single building blocks), services (multiple modules combined for production deployment), and architectures (full environments).

Cross-module communication has three mechanisms, in rough order of preference for loose coupling: explicit inputs and outputs (pass values through the root module), the terraform_remote_state data source as glue between separately-stated layers (for example, a network layer exposing subnet IDs that a compute layer consumes), and provider data sources to look up existing objects. Remote-state reads introduce dependency chains that must be managed to avoid tight coupling or circular references.

Dependency inversion is the key decoupling pattern: modules accept their dependencies as inputs (object-typed where helpful) so the root module can wire the same modules together differently for different results. This is what makes a flat composition flexible and is the recommended alternative to a module embedding and managing its own dependencies.

### 7. Code organization and DRY principles

Repository structure: a common pattern is a modules/ directory of reusable components plus an environments/ directory of per-environment compositions, with separate pipeline definitions. For larger organizations, composition-based polyrepo layouts (one repo per module, composed via a separate environments repo) support independent team ownership and repository-level RBAC; monorepo layouts are simpler for smaller teams. HashiCorp notes versioning each module in its own repository enables devolved security through repository RBAC.

Module registry usage: a private registry adds versioning, search, discoverability, and access control; HashiCorp suggests moving a module to a registry once multiple teams consume it. Use the public registry to avoid reinventing common patterns, but review and pin third-party modules.

Environment promotion: promote the same versioned module/configuration through environments by changing only inputs, validating in lower environments before production. Separate configuration from code: keep sensible defaults in variables and supply environment-specific values via tfvars files or a workspace/variable-set mechanism, rather than forking code per environment. Anton Babenko's terraform-best-practices guide recommends using data sources and terraform_remote_state specifically as glue between infrastructure modules within a composition, and grouping example projects by infrastructure size.

### 8. Testing and validation

A layered testing pyramid is the consensus model:

- Static guardrails (fast, no cloud credentials): terraform fmt (formatting, enforce with -check in CI and pre-commit hooks), terraform validate (syntax and internal consistency), and terraform plan for review.
- Linting and security scanning: TFLint (best-practice and provider-specific rules, account-limit checks), Checkov, tfsec/Trivy, and Terrascan for security and compliance misconfiguration detection. Run these in CI and as pre-commit hooks.
- Unit/logic testing: the native terraform test framework. Per HashiCorp's October 2023 blog "Terraform 1.6 adds a test framework," "The general availability of Terraform 1.6 brings a new Terraform test framework that deprecates and replaces the previous experimental feature first added in version 0.15." Tests are written in HCL in files ending .tftest.hcl or .tftest.json, loaded from the root directory and the tests/ subdirectory. Each file has run blocks (executed sequentially), an optional variables block, optional provider blocks, and assert blocks with condition and error_message. The command argument is apply by default (creates real infrastructure, integration-style) or plan (no infrastructure created, unit-style logic validation). Provider mocking via mock_provider, plus override_resource, override_data, and override_module, lets you test without creating real infrastructure or credentials. Per HashiCorp's Provider Mocking docs, "Test mocking is available in Terraform v1.7.0 and later," and a mocked provider "will generate fake data for all computed attributes that would normally be provided by the underlying provider APIs." HashiCorp's Dan Barr (Technical Product Marketing Manager) framed the 1.7 addition: "it can also be useful to mock provider calls to model more advanced situations and to test without having to create actual infrastructure or requiring credentials." Reuse example configurations as test fixtures so documentation stays valid.
- Integration testing: Terratest (Go library by Gruntwork; deploys real infrastructure, asserts, then destroys) and the older Kitchen-Terraform (Ruby/InSpec). Terratest is more featureful and extensible; the native framework avoids learning Go and keeps tests in HCL.
- Policy as code: Sentinel (HashiCorp) or Open Policy Agent/Conftest to enforce organizational compliance guardrails before apply.

HashiCorp's own framing: modules that expose fewer inputs, provide sensible defaults, and enforce guardrails are less likely to be misused; do not use modules themselves as a security/compliance tool, and validate inputs early with validation blocks. Run tests on pull requests and block merges on failure. Do not attempt to test every input combination; test realistic usage patterns.

### 9. CI/CD for Terraform

The non-negotiable pattern is separating plan from apply with human approval in between. Run terraform plan on every pull request, post the plan for review, and apply only after the PR is approved and merged. Use the same execution environment for plan and apply so the reviewed plan matches what is applied; save and apply the reviewed plan artifact rather than re-planning inside the apply job.

Pull request automation: on PR, run fmt -check, validate, lint, security scans, and tests, then a speculative plan commented back to the PR. Use approval gates (environment protection rules, required reviews, label-based gates) before apply. Serialize applies per environment with concurrency controls to avoid lock contention.

Secret management in pipelines: never put credentials in Terraform config or pipeline definition files. Prefer short-lived credentials issued via OIDC over long-lived static keys, scoped per environment and per run, injected as environment variables at runtime. HashiCorp recommends provider credentials be supplied via environment variables because they are not persisted in the plan file or to disk.

Drift detection: run scheduled terraform plan with -detailed-exitcode (exit code 2 signals drift) to detect out-of-band changes, alerting or opening issues on detection. Auto-remediation is acceptable for non-production but production drift should be reviewed by a human, since a manual change may have been an emergency fix to incorporate rather than revert. Note the plan file contains a full copy of configuration, state, and variables, so protect plan artifacts if they may contain sensitive data.

### 10. Security and secrets

- Keep secrets out of code and state where possible. Sensitive values marked sensitive are redacted from output but still stored in state; ephemeral values and write-only arguments (provider-dependent) avoid persisting to state at all. Model sensitive external objects as ephemeral resources when supported.
- Never hardcode secrets; source them from a dedicated secrets manager (Vault, and cloud-native equivalents) or inject at runtime. Never default secret variables.
- State file encryption: enable encryption at rest on the backend and enforce TLS in transit; encrypt backups and cached state too. Use a dedicated state bucket/container with least-privilege access policies and versioning. HashiCorp deprecates the older PGP-key-in-state pattern in favor of encrypted remote backends.
- Least-privilege execution: grant the Terraform execution identity only the permissions it needs, segmented per environment, replacing personal/admin credentials with scoped service identities.

### 11. Common anti-patterns to avoid

- Over-modularization: too many tiny modules and thin single-resource wrappers add indirection without abstraction.
- Under-modularization (god modules): monolithic root modules bundling unrelated domains inflate state and coupling.
- Hardcoded values: replace values that vary between runs or environments with variables; use jsonencode/yamlencode and templating rather than hand-built strings.
- count versus for_each misuse: count tracks instances by positional index, so removing a middle element shifts indices and forces destroy/recreate of unintended resources. Use for_each (keyed by a map or set) whenever instances have distinct identity, so removals affect only the targeted key. Reserve count for genuinely identical instances and for conditional creation (count = var.enabled ? 1 : 0). Note for_each keys must be known at plan time; count can sometimes work when values are only known after apply. The HashiCorp style guide advises using count and for_each sparingly overall.
- Implicit dependencies and hidden ordering: rely on natural references so Terraform infers order; use depends_on only when necessary.
- Module proliferation: uncontrolled growth of overlapping modules; mitigate with a registry, ownership, and curation.
- Provisioners: treat provisioners as a last resort.

### 12. Refactoring and lifecycle management

Terraform provides declarative, version-controlled refactoring blocks (preferred over imperative terraform state mv):

- moved (Terraform 1.1+): maps an old resource/module address to a new one so Terraform updates state instead of destroying and recreating. Use it for renames, extracting resources into modules, renaming modules, and switching between count and for_each keys. Constraints: source and destination must be in the same state; cannot change resource type (except provider-supported cross-type moves in 1.8+); cannot be conditional. Always run plan and confirm it shows moves, not destroy/create. Keep moved blocks for at least one full apply cycle across all environments before removing them (removing a moved block is itself a breaking change), and a common convention is to consolidate them in a moved.tf manifest and clean them up at the next major version.
- removed: removes a resource from state while controlling whether the real object is destroyed (lifecycle { destroy = false } to relinquish management without deleting).
- import (configuration-driven, 1.5+): brings existing infrastructure under management declaratively.

For module breaking changes, ship moved blocks inside the module so consumers upgrade without destroy/recreate cycles, maintain a CHANGELOG, and for complex migrations provide a one-time migration module and a documented step-by-step migration guide. Coordinate large refactors through a single branch because conflicting moved blocks on different branches cause confusing errors at merge.

## Recommendations

1. Establish the module contract first. For the workspace-deployment module and every module after it, mandate: standard file layout (main/variables/outputs/versions, README, examples), typed and described inputs, nullable = false on required inputs, sensitive on secrets with no defaults, object-typed inputs with optional() for complex configuration, and proactively exposed outputs. This interface contract is what you will version, so design it for additive evolution.

2. Default to flat composition with dependency inversion. Build small single-responsibility modules and assemble them in thin root-module compositions. Pass dependencies in as inputs rather than fetching or creating them inside modules. Do not nest modules deeply, and do not write single-resource wrappers.

3. Lock down versioning and state from day one. Child modules declare lower-bound provider constraints; root modules pin tightly and commit .terraform.lock.hcl. Use remote state with locking and encryption, isolated per environment and per layer, with least-privilege backend access and production write access limited to the pipeline.

4. Make quality gates mandatory in CI. Pre-commit and CI run fmt -check, validate, TFLint, and a security scanner (Checkov or tfsec). Add native terraform test (plan-command unit tests with mock_provider; apply-command integration tests against the examples directory) and policy-as-code (Sentinel or OPA) before apply.

5. Adopt plan-then-apply with approval and OIDC credentials. Plan on PR with the plan posted for review; apply the saved plan artifact only after merge and approval, using short-lived OIDC credentials scoped per environment. Add scheduled drift detection with -detailed-exitcode, human-reviewed in production.

6. Standardize refactoring discipline. Require moved blocks (in a moved.tf manifest) for any address change, one logical change per PR, plan verification showing moves not destroy/create, semantic versioning, a changelog, and migration guides for major versions.

Thresholds that change these recommendations: if a module is only ever a one-to-one passthrough of a single resource's inputs, do not make it a module (use the resource directly or a public module). Promote a module into a private registry once three or more teams consume it. Move from CLI workspaces to directory/backend isolation as soon as environments diverge architecturally or require different blast-radius or permission boundaries. Reserve count for genuinely identical or conditional resources; use for_each everywhere identity matters.

## Caveats

- Source quality: HashiCorp's official developer docs, style guide, and the "How to write and rightsize Terraform modules" blog (authored by HashiCorp's Mitch Pronschinske, drawing on Rene Schach's HashiDays 2025 session) are primary and authoritative. Several specifics (CI/CD templates, drift-detection scripts, registry-adoption thresholds) draw on community sources (Gruntwork, Cloud Posse, Anton Babenko, Spacelift, Scalr, vendor prescriptive guidance); these are widely respected but represent practitioner consensus rather than HashiCorp mandates, and some statistics cited in secondary articles are unverifiable.
- I could not find a verbatim primary-source HashiCorp statement that native test files should specifically reuse the examples directory; that is community best practice (notably Gruntwork's Terratest conventions) rather than an explicit rule in HashiCorp's test-framework reference pages. HashiCorp does document the examples/ directory convention and does recommend writing and running tests in CI.
- Version sensitivity: capabilities are version-gated (moved 1.1+, import blocks 1.5+, native test 1.6+, provider mocking and removed-block enhancements 1.7+, S3 native state locking 1.10+, write-only arguments 1.11+). Confirm the framework's minimum supported Terraform version before relying on a feature.
- Scope: per the request, this summary is general-purpose and deliberately excludes vendor-specific authentication, provider-specific pitfalls, and any product-specific guidance. Validate the general patterns against the specific providers the framework will target as scope expands.