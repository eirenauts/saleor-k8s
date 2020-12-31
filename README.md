# saleor-k8s

[![Build Status](https://dev.azure.com/eirenauts/saleor-k8s/_apis/build/status/eirenauts.saleor-k8s?branchName=master)](https://dev.azure.com/eirenauts/saleor-k8s/_build/latest?definitionId=1&branchName=master) [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://choosealicense.com/licenses/apache-2.0/)

## saleor charts

The umbrella chart required to deploy the entire saleor ecommerce platform is the `saleor-platform` chart.

### List of charts

| Chart Name        | Notes                                                                                                                                                 |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| saleor-core       | Handles deployment of `saleor-core` application. Includes a number of jobs for initialization tasks.                             |
| saleor-dashboard  | Handles deployment of `saleor-dashboard` application as an nginx application. Required for the front end admin dashboard.                             |
| saleor-storefront | Handles deployment of `saleor-dashboard` application as an nginx application. Required for the front end UI where customers land.                     |
| saleor-platform   | This is an umbrella chart. It does not deploy any single application but rather is deploys a collection of subcharts required for saleor to function. |

### Example helm deployment

There is freedom to deploy the `saleor-platform` chart in a number of different ways - not all of which have been tested out.

An example deployment of saleor is illustrated in the [example README.md](./example/README.md).

Some changes need to be made to suit your specific requirements.

### List of Images

| Image                                                                                                | Version                                                                                                                                                | Runtime Base Image                   | Key Components                                             | Purpose                                                                                                                                        |
| ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------ | ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| [saleor-core](https://github.com/users/eirenauts/packages/container/package/saleor-core)             | [![Docker Version](https://img.shields.io/badge/version-2.11.1-blue)](https://github.com/users/eirenauts/packages/container/package/saleor-core)       | `python:3.8.6-slim`                  | `saleor core application - django, graphql, ecommerce app` | Backend for the saleor platform. Required for k8s deployments.                                                                                 |
| [saleor-dashboard](https://github.com/users/eirenauts/packages/container/package/saleor-dashboard)   | [![Docker Version](https://img.shields.io/badge/version-2.11.1-blue)](https://github.com/users/eirenauts/packages/container/package/saleor-dashboard)  | `nginxinc/nginx-unprivileged:1.19.5` | `javascript, reactjs`                                      | Frontend for the admin dashboard for the saleor platform. Required for k8s deployments.                                                        |
| [saleor-storefront](https://github.com/users/eirenauts/packages/container/package/saleor-storefront) | [![Docker Version](https://img.shields.io/badge/version-2.11.1-blue)](https://github.com/users/eirenauts/packages/container/package/saleor-storefront) | `nginxinc/nginx-unprivileged:1.19.5` | `javascript, reactjs`                                      | Default frontend for the storefront for the saleor platform. Required for k8s deployments. Fork this if it is necessary to create a custom UI. |

## Licence

[Apache 2.0](https://choosealicense.com/licenses/apache-2.0/)
