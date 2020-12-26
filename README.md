# saleor-k8s

## saleor charts

## saleor containers

[![Build Status](https://dev.azure.com/eirenauts/saleor-k8s/_apis/build/status/eirenauts.saleor-k8s?branchName=master)](https://dev.azure.com/eirenauts/saleor-k8s/_build/latest?definitionId=1&branchName=master) [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://choosealicense.com/licenses/apache-2.0/) ![Semver Version](https://img.shields.io/github/v/tag/eirenauts/saleor-k8s?color=blue&sort=semver)

This repository is a collection of build files for the saleor container images.

### List of Images

| Image                                                                                                 | Version                                                                                                                                                | Base Image                           | Key Components                                             | Purpose                                                                                                                                        |
| ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------ | ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| [saleor-core](https://github.com/users/eirenauts/packages/container/package/saleor-core)             | [![Docker Version](https://img.shields.io/badge/version-1.3.0-blue)](https://github.com/users/eirenauts/packages/container/package/saleor-core)       | `python:3.8.6-slim`                  | `saleor core application - django, graphql, ecommerce app` | Backend for the saleor platform. Required for k8s deployments.                                                                                 |
| [saleor-dashboard](https://github.com/users/eirenauts/packages/container/package/saleor-dashboard)   | [![Docker Version](https://img.shields.io/badge/version-1.3.0-blue)](https://github.com/users/eirenauts/packages/container/package/saleor-dashboard)  | `nginxinc/nginx-unprivileged:1.19.5` | `javascript, reactjs`                                      | Frontend for the admin dashboard for the saleor platform. Required for k8s deployments.                                                        |
| [saleor-storefront](https://github.com/users/eirenauts/packages/container/package/saleor-storefront) | [![Docker Version](https://img.shields.io/badge/version-1.3.0-blue)](https://github.com/users/eirenauts/packages/container/package/saleor-storefront) | `nginxinc/nginx-unprivileged:1.19.5` | `javascript, reactjs`                                      | Default frontend for the storefront for the saleor platform. Required for k8s deployments. Fork this if it is necessary to create a custom UI. |

## Licence

[Apache 2.0](https://choosealicense.com/licenses/apache-2.0/)
