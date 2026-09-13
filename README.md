# 🏠 johto

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

## Repository Layout

```text
nix/
├── hosts/nixos/       Per-host NixOS configuration and hardware state
└── nixos/             Shared modules, features, services, and users
k8s/                  Flux, Kustomize, Helm, and application manifests
secrets/              SOPS-encrypted host and Kubernetes secrets
keys/                 Public SSH keys used to derive age recipients
terraform/            OpenTofu configuration for Cloudflare DNS
scripts/              Repository maintenance utilities
```

`flake.nix` assembles the Nix modules and exposes the `olivine`, `goldenrod`,
and `cherrygrove` NixOS configurations. Kubernetes applications are grouped by
service under `k8s/`; `k8s/flux-system/` defines their reconciliation order.

## Development

Enter the pinned toolchain with `nix develop`, or run `direnv allow` to load it
automatically. Useful commands from the repository root include:

```bash
# Format Nix, YAML, Markdown, TypeScript, and shell files.
nix fmt

# Evaluate the flake and run its configured checks.
nix flake check

# Build a host configuration without activating it.
nix build .#nixosConfigurations.olivine.config.system.build.toplevel
nix build .#nixosConfigurations.goldenrod.config.system.build.toplevel
nix build .#nixosConfigurations.cherrygrove.config.system.build.toplevel

# Refresh the generated host hardware documentation.
nix run github:alyraffauf/infra#generate-host-readmes

# Discover repository maintenance recipes.
just
```

CI evaluates the flake, builds the development shell, and builds all NixOS
hosts. Kubernetes changes are deployed through Flux after they reach
`master`; avoid applying repository manifests manually unless recovering the
cluster.

## NixOS Deployments

`nix/deployments.nix` registers both hosts with `blzrd`. From the development
shell, deploy only the intended host whenever possible:

```bash
blzrd switch olivine       # Activate Olivine and set its boot default
blzrd switch goldenrod     # Activate Goldenrod and set its boot default
blzrd boot olivine         # Set Olivine's next boot without activating it
blzrd switch               # Deploy both registered hosts
```

Run the checks and build the affected host first. Supplying no node names
targets every registered node, so reserve the bare command for coordinated
fleet deployments.

## Secrets and DNS

Secrets are encrypted with SOPS for the recipients declared in `.sops.yaml`.
Never commit decrypted values or OpenTofu state.

```bash
just sops-bootstrap             # Install this machine's age key once
just sops-edit tailscale.yaml   # Edit an encrypted secret
just sops-rekey                 # Update recipients after keys/ changes
```

Direnv decrypts the Cloudflare and Backblaze credentials used by OpenTofu.
Review DNS changes before applying them:

```bash
tofu -chdir=terraform init
tofu -chdir=terraform plan
tofu -chdir=terraform apply
```

See [AGENTS.md](AGENTS.md) for contribution and validation guidelines.
