# Erpf Charts

This Repository contains all the charts used by Erpf for different components and is maintained by Jakob Erpf.

## Introduction

Some charts are used by Devtron for its functionality and other charts are also provided which can be used to add additional features and components in Devtron Cluster.

The Charts with its functionality is listed below:

- [iam](https://github.com/) as an end-to-end indentiy and access management with Keycloak
- [bashub](https://github.com/) as terminal command history/repository with Bashhub
- [vaultwarden](https://github.com/) as an end-to-end indentiy and access management with Keycloak

## How to use the charts

### Install with Helm

These charts are currently not available on the official helm repository therefore you need to download it to install.

```bash
helm repo add erpf http://helm.erpf.de
helm install <release-name> erpf/<chart-name>
```