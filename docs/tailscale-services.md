# Tailscale services

Johto exposes private web apps through the shared `private-ingress` ProxyGroup.
Each Ingress creates one Tailscale Service at
`<hostname>.narwhal-snapper.ts.net`. The proxy runs on Goldenrod and forwards
to the Kubernetes Service. These are tailnet-only routes. They are unrelated
to Olivine's public ingress.

The current examples live in `k8s/private-ingress/`. Start with the one whose
namespace and service port look most like the app you are adding.

## Add a service

Create `k8s/private-ingress/<app>.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <app>-johto
  namespace: <namespace>
  annotations:
    tailscale.com/proxy-group: private-ingress
spec:
  ingressClassName: tailscale
  tls:
    - hosts:
        - <hostname>
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: <service>
                port:
                  name: <port-name>
```

`<hostname>` is only the first DNS label. For example, `navidrome` becomes
`navidrome.narwhal-snapper.ts.net`. Pick a name that is not already used by a
service or a MagicDNS device.

Add the file to `k8s/private-ingress/kustomization.yaml`.

If the backend has an ingress NetworkPolicy, allow the application's container
port from the `tailscale` namespace and pods with these labels:

```yaml
tailscale.com/managed: "true"
tailscale.com/parent-resource-type: proxygroup
tailscale.com/parent-resource: private-ingress
```

Use a single peer containing both `namespaceSelector` and `podSelector`, as in
`k8s/audiobookshelf/network-policy.yaml`. The proxy has no egress allowlist.
Tailscale discovers its public endpoints without a configured home WAN address.

If you changed a backend policy, stage that file with `git add` before committing.
Then check the Kubernetes resources and commit the route:

```sh
nix run .#check-k8s
git add k8s/private-ingress
git commit -m "feat(private-ingress): expose <app> through Tailscale"
git push
```

Flux normally catches the commit within ten minutes. For an immediate deploy,
use the Johto context explicitly. The default local context may be another
cluster.

```sh
nix run nixpkgs#fluxcd -- --context johto reconcile source git flux-system -n flux-system
nix run nixpkgs#fluxcd -- --context johto reconcile kustomization private-ingress -n flux-system --with-source
```

## Check the route

The operator creates the service, configures the proxy, and obtains the TLS
certificate. It can take a minute or two after the Ingress appears.

```sh
kubectl --context johto -n <namespace> get ingress <app>-johto -o wide
kubectl --context johto -n <namespace> describe ingress <app>-johto
kubectl --context johto -n tailscale logs statefulset/private-ingress --since=10m
```

The Ingress `ADDRESS` should become
`<hostname>.narwhal-snapper.ts.net`. If the service has zero hosts in the
Tailscale admin panel, approve `private-ingress-0` for that service. The
service then shows one host with `approved:manual` and `ready`.

Test it from a tailnet client:

```sh
curl --fail --connect-timeout 10 --max-time 20 \
  https://<hostname>.narwhal-snapper.ts.net/
```

Some apps return a redirect, an authentication response, or another non-200
success response. What matters is that the connection reaches the app.

## If a name is genuinely blocked

Most new services do not need cleanup. Do not delete a service just because
the name already exists. First inspect it. A service with a
`tailscale.com/owner-references` annotation already belongs to a Kubernetes
operator. Reconcile the Ingress and let that operator keep it.

Only delete a service when it is a stale, non-operator resource that blocks a
planned replacement. This uses the OAuth client already stored for the
Tailscale operator. It does not print the client secret or access token.

```sh
set -euo pipefail

values=$(sops --decrypt k8s/secrets/tailscale-operator-values.sops.yaml \
  | yq -r ".data.\"values.yaml\"" | base64 --decode)
client_id=$(printf "%s" "$values" | yq -r ".oauth.clientId")
client_secret=$(printf "%s" "$values" | yq -r ".oauth.clientSecret")
token=$(curl --fail --silent --show-error \
  --user "$client_id:$client_secret" \
  --data "grant_type=client_credentials" \
  https://api.tailscale.com/api/v2/oauth/token | jq -r ".access_token")

curl --fail --silent --show-error \
  --header "Authorization: Bearer $token" \
  "https://api.tailscale.com/api/v2/tailnet/-/vip-services/svc:<hostname>" \
  | jq "{name, annotations, ports, tags}"
```

If that inspection shows an unowned stale service, run this in its own shell.
It repeats the token setup so the delete request cannot accidentally run with
an expired or missing token. Reconcile Flux afterwards.

```sh
set -euo pipefail

values=$(sops --decrypt k8s/secrets/tailscale-operator-values.sops.yaml \
  | yq -r ".data.\"values.yaml\"" | base64 --decode)
client_id=$(printf "%s" "$values" | yq -r ".oauth.clientId")
client_secret=$(printf "%s" "$values" | yq -r ".oauth.clientSecret")
token=$(curl --fail --silent --show-error \
  --user "$client_id:$client_secret" \
  --data "grant_type=client_credentials" \
  https://api.tailscale.com/api/v2/oauth/token | jq -r ".access_token")

curl --fail --silent --show-error --request DELETE \
  --header "Authorization: Bearer $token" \
  "https://api.tailscale.com/api/v2/tailnet/-/vip-services/svc:<hostname>"
```

Do not delete the operator-managed replacement after it has taken ownership.
