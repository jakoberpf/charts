# 🚢 Regularly and Automatically Updated Helm Charts

These charts are mainly developed for community use and for the `Erpf & Boghdady` cloud.

- TODO update CI with https://github.com/sagikazarmark/helm-charts

## Introduction

The Charts with its functionality is listed below:

- [keycloak](https://github.com/jakoberpf/charts/tree/main/charts/keycloak) as an end-to-end identity and access management
- [ory](https://github.com/) as an end-to-end identity and access management (replacement of Keycloak)
- [bashub](https://github.com/jakoberpf/charts/tree/main/charts/bashhub) as terminal command history/repository with Bashhub
- [vaultwarden](https://github.com/jakoberpf/charts/tree/main/charts/vaultwarden) as an personal password manager
- [vault](https://github.com/jakoberpf/charts/tree/main/charts/vault) as an secret manager and store
- [teleport](https://github.com/jakoberpf/charts/tree/main/charts/teleport) as an cluster, virtual machine and database access service
- [netmaker](https://github.com/jakoberpf/charts/tree/main/charts/netmaker) as a wireguard based software defined network service
- [zerotier-bridge](https://github.com/jakoberpf/charts/tree/main/charts/zerotier-bridge) as a bridge into a zerotier network
- [zerotier-controller](https://github.com/jakoberpf/charts/tree/main/charts/zerotier-controller) as a controller for the zerotier software defined network

## How to use the charts

### Install with Helm

These charts are currently not available on the official helm repository therefore you need to download it to install.

```bash
helm repo add jakoberpf https://jakoberpf.github.io/charts/
helm install <release-name> jakoberpf/<chart-name>
```

These chart are also pushed into the Github Registry.

```bash
helm install <release-name> oci://ghcr.io/jakoberpf/charts/<chart-name> --version <chart-version>
```

## Secrets

```bash
sops --encrypt test/tunnel-credentials.json > test/tunnel-credentials.json.enc
```

## Roadmap

- Add vaultwarden backup solution https://github.com/ttionya/vaultwarden-backup/tree/master
- Add vaultwarden tests with cli client https://github.com/bitwarden/clients/tree/master/apps/cli
