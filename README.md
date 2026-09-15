# johto

Declarative infrastructure for my personal homelab. Johto combines NixOS,
k3s, Flux, SOPS, and OpenTofu to manage the hosts, applications, networking,
DNS, and backups that keep the lab running.

If you're looking for my production services, see [sinnoh](https://github.com/devon-systems/sinnoh).
For my personal nix flake, check out [hoenn](https://github.com/alyraffauf/hoenn).

## Architecture

| Host          | Role                                                                                                    |
| ------------- | ------------------------------------------------------------------------------------------------------- |
| `olivine`     | k3s server and control plane, public ingress workloads, private DNS, and etcd backups                   |
| `goldenrod`   | k3s worker for media workloads, persistent storage, NFS, Garage, observability, and application backups |
| `cherrygrove` | Persistent NixOS MicroVM hosted by Goldenrod                                                            |

The nodes communicate over a dedicated WireGuard network. Tailscale provides
private service access, while public services enter through Olivine. Flux
reconciles Kubernetes resources from the `master` branch.

The cluster runs a mix of personal cloud, media, and operations services,
including Immich, Nextcloud, Paperless, Pocket ID, Plex, Jellyfin, the Servarr
stack, CloudNativePG, Prometheus, Loki, and Uptime Kuma.

## Repository layout

```text
nix/
├── hosts/nixos/       Per-host NixOS configuration and hardware state
└── modules/           Host defaults and feature modules
k8s/                  Flux, Kustomize, Helm, and application manifests
secrets/              SOPS-encrypted host secrets
keys/                 Public SSH keys used to derive age recipients
terraform/            OpenTofu configuration for Cloudflare DNS
scripts/              Repository maintenance utilities
```

`flake.nix` assembles the Nix modules and exposes the `olivine`, `goldenrod`,
and `cherrygrove` NixOS configurations. Kubernetes applications are grouped by
service under `k8s/`. `k8s/flux-system/` defines their reconciliation order.

## Work locally

Enter the pinned development shell with `nix develop`, or use `direnv allow`
to load it automatically. From the repository root:

```sh
nix fmt
nix flake check
```

Run `just` to list maintenance commands. See [AGENTS.md](AGENTS.md) for checks
specific to your change, generated files, and secret maintenance.

## Deployment

`blzrd` deploys `olivine` and `goldenrod`. For example:

```sh
blzrd switch olivine
```

`switch` activates the configuration and sets the boot default. `boot` sets
the boot default without activating it. Deployment checks and precautions are
in [AGENTS.md](AGENTS.md#deploy-deliberately).

Flux deploys Kubernetes workloads from `master`. OpenTofu manages DNS.

## Secrets

SOPS encrypts secrets for the recipients in `.sops.yaml`. Public keys live in
`keys/`. To edit a host secret from the development shell:

```sh
just sops-edit tailscale.yaml
```

Direnv loads the encrypted Cloudflare and Backblaze credentials for OpenTofu.

See [AGENTS.md](AGENTS.md) for contribution and validation guidelines.
