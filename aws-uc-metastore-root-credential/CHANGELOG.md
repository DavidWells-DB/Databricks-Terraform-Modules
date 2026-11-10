# Changelog

All notable changes to the `aws-uc-metastore-root-credential` module are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this module adheres to [Semantic Versioning](https://semver.org/)

## [Unreleased]

## [0.1.0] - 2026-11-10

### Added
- Initial module: the metastore root-storage credential at the ACCOUNT plane — one `databricks_metastore_data_access` on the GIVEN metastore (the right metastore by construction), plus the IAM role whose trust policy is built from THAT credential's external_id (the aws-uc-storage-credential choreography, adapted to the metastore plane). Replaces the broken workspace-scoped path: a workspace-plane `databricks_storage_credential` registers against the AUTO-ASSIGNED default metastore (not the new one), and its external_id does not match a metastore-plane data access.
- UNVERIFIED LIVE (no credentials in this build): the external_id-readback apply path and the IAM validation on second apply. Plan-verified only; promote after a live apply.
