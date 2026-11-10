# Changelog

All notable changes to the `dbx-plan-guard` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.1.0] - 2026-11-10

### Added
- Initial module: the honesty-layer marker pattern as a shared module — one-time-direction `guards` (recorded at first apply, frozen, plan-FAILING postcondition when a true flag flips to false: the CSP/legacy irreversibility + destroy-sentinel semantics) and plan-visible non-blocking `notices`. Deliberately NOT check blocks (checks only warn; these must fail). Escape hatch documented (state rm the marker). No providers — pure terraform_data.
- Plan tests covering the guard semantics (both directions + multiple keys) and notices.
