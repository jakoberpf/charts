# charts

This Repository contains all the charts used by jakoberpf for different components and is maintained by Jakob Boghdady.
These charts are mainly developed for community use and for the `Erpf & Boghdady` cloud.

- TODO update CI with https://github.com/sagikazarmark/helm-charts

## Introduction

Some charts are used by Devtron for its functionality and other charts are also provided which can be used to add additional features and components in Devtron Cluster.

The Charts with its functionality is listed below:

- [keycloak](https://github.com/jakoberpf/charts/tree/main/charts/keycloak) as an end-to-end identity and access management
- [ory](https://github.com/) as an end-to-end identity and access management (replacement of Keycloak)
- [bashub](https://github.com/jakoberpf/charts/tree/main/charts/bashhub) as terminal command history/repository with Bashhub
- [vaultwarden](https://github.com/jakoberpf/charts/tree/main/charts/vaultwarden) as an personal password manager
- [vault](https://github.com/jakoberpf/charts/tree/main/charts/vault) as an secret manager and store
- [teleport](https://github.com/jakoberpf/charts/tree/main/charts/teleport) as an cluster, virtual machine and database access service

## How to use the charts

### Install with Helm

These charts are currently not available on the official helm repository therefore you need to download it to install.

```bash
helm repo add erpf http://helm.erpf.de
helm install <release-name> erpf/<chart-name>
```
