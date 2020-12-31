# Changelog

**_Please follow the [keep a changelog conventions](https://keepachangelog.com/en/1.0.0/)_**

## saleor-platform-0.1.0

**_Added_**

- example deployment using ansible kubernetes community helm module

**_Removed_**

- Removed `backups` logic as it is not ready for release
- References to RESTIC variables removed as the feature is not ready for release

**_Fixed_**

- Collectstatic script and function was broken.
- `init_helm` missing from init phase but the dependency is required
- issue in bash script fixed on substituting the env variables on startup
- fixed small issues in build pipeline with failures downloading chart repos

## saleor-platform-0.0.1

Release following charts to `https://eirenauts.github.io/saleor-k8s`

- `saleor-platform-0.0.1`
- `saleor-core-0.0.1`
- `saleor-dashboard-0.0.1`
- `saleor-storefront-0.0.1`

Push docker images

- `ghcr.io/eirenauts/saleor-core:2.11.1`
- `ghcr.io/eirenauts/saleor-dashboard:2.11.1`
- `ghcr.io/eirenauts/saleor-storefront:2.11.1`

**_Added_**

- Saleor source code built as docker images rebuilt with customizations required for the k8s deployments.
- Added initial helm charts with each component in it's own chart, namely:
  - saleor-core
  - saleor-storefront
  - saleor-dashboard
- Added an umbrella chart with all chart dependencies (sub-charts) specified for consumption.
- Added scripts and makefile for CI operations.
