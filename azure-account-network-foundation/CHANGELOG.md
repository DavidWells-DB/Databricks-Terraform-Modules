# Changelog

All notable changes to the `azure-account-network-foundation` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.1.0] - 2026-11-10

### Added
- Initial module: the ADR-0007 account-foundation surface for Azure — the NCC (azure-account-network-connectivity-config v0.2.0+, pure NCC after the H5-1 policy consolidation) plus the optional account network policy (dbx-account-network-policy) composed in one call, each object from its single-owner module. Workspaces bind by ID via dbx-workspace-network-serverless (NCC) and dbx-workspace-network-policy-binding (policy).
- Plan tests with mock_provider covering the composition, the NCC-only default, and the policy-enabled path.
