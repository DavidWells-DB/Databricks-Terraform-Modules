# Changelog

All notable changes to the `dbx-uc-workspace-binding` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.1.0] - 2026-11-10

### Added
- Initial module: catalog→workspace (and other securable) workspace bindings via the CURRENT `databricks_workspace_binding` resource (its `databricks_catalog_workspace_binding` twin is deprecated at this provider version). The finisher for `dbx-uc-catalog`'s `isolation_mode = "ISOLATED"` — that un-shares the catalog; these bindings re-grant the intended workspaces. Design after the config-driven prior art (reviewed): caller-keyed map (for_each constants), read-only/read-write via binding_type, either provider surface.
- Plan tests with mock_provider covering defaults, the isolation pairing shape, and variable validations.
