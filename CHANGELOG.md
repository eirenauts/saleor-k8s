# Changelog

**_Please follow the [keep a changelog conventions](https://keepachangelog.com/en/1.0.0/)_**

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
