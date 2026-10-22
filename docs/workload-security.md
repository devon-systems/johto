# Workload security

Application pod templates disable service account tokens and service-link
environment variables. Containers prevent privilege escalation and drop
`NET_RAW`. Pod seccomp profiles use `RuntimeDefault`.

Collabora and Gotenberg retain their browser sandbox permissions. Uptime Kuma
retains its capabilities for ICMP monitors. Existing image users, writable
filesystems, GPU devices, and volume ownership remain application-specific.
Infrastructure controllers retain the Kubernetes API access they require.

## Network policies

Policies beside each application's manifests select its pods by label.
Nextcloud, Collabora, Paperless, Immich, Pocket ID, Happyview, Ombi, Hydrant,
and Watsup accept traffic from Traefik and their declared health callers.
Their outbound rules allow DNS, public web requests, and specific application
dependencies. Mail ports are allowed only for applications that use them.
Existing Valkey, Tika, and Gotenberg policies restrict access to their clients.

Public outbound rules exclude private, tailnet, link-local, reserved, and
cluster public ingress addresses. Standard NetworkPolicy cannot select
external services by hostname. An allowed public web port can reach any
public address outside those exclusions.

Nextcloud reaches Garage on Goldenrod at `10.254.2.3:3900`. Ombi and Watsup
reach Plex there on port `32400`. Collabora calls Nextcloud through
`http://nextcloud.nextcloud.svc`. The Nextcloud startup hook sets the trusted
domains and Office callback URL. Browser URLs remain public HTTPS URLs.
Watsup uses internal health URLs for local services.

## Exceptions and limits

Uptime Kuma has restricted ingress and unrestricted outbound access for
monitors. Plex retains host networking. Private applications without an
egress policy retain their existing network access.

Policies are additive. Another policy that selects the same pod can grant
additional access. K3s uses kube-router to enforce these rules over Flannel.
NetworkPolicy does not provide complete isolation from the pod's own node,
host-network workloads, or host services. Host firewall rules and container
permissions remain separate controls.
