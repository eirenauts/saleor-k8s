# Changelog

**_Please follow the [keep a changelog conventions](https://keepachangelog.com/en/1.0.0/)_**

## Unreleased

**_Added_**

- Saleor source code built as docker images rebuilt with customizations required for the k8s deployments.
- Added initial helm charts with each component in it's own chart, namely:
  - saleor-core
  - saleor-storefront
  - saleor-dashboard
- Added an umbrella chart with all chart dependencies (sub-charts) specified for consumption.
- Added scripts and makefile for CI operations.
