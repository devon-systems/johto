_: {
  flake.nixosModules.wireguardJohto = {
    config,
    lib,
    pkgs,
    self,
    ...
  }: let
    nodes = {
      olivine = {
        address = "10.254.2.2";
        endpoint = "51.81.32.154:51820";
        publicKey = "v+Up5bpwOcV8Rg8r5oP5ru2gYezja4Db4+NHiiF+HUA=";
      };

      goldenrod = {
        address = "10.254.2.3";
        publicKey = "gzAi+LGwbC6VQXTKs/KCKp2Mu+JU6VQMb02z9rXfNDw=";
      };
    };

    hostName = config.networking.hostName;
    currentNode = nodes.${hostName};
    peerNodes = lib.filterAttrs (nodeName: _: nodeName != hostName) nodes;
    peerName = builtins.head (builtins.attrNames peerNodes);
    peer = peerNodes.${peerName};
    resolvectl = lib.getExe' pkgs.systemd "resolvectl";
    wireguard = lib.getExe pkgs.wireguard-tools;
    gawk = lib.getExe pkgs.gawk;

    wireguardMetrics = pkgs.writeShellApplication {
      name = "johto-wireguard-metrics";
      runtimeInputs = [pkgs.coreutils pkgs.gawk pkgs.wireguard-tools];
      text = ''
        set -eu

        directory=/var/lib/johto-metrics
        output="$directory/wireguard-johto.prom"
        temporary=$(mktemp "$directory/wireguard-johto.XXXXXX")
        trap 'rm -f "$temporary"' EXIT

        ${wireguard} show johto dump | ${gawk} \
          -v peer_key='${peer.publicKey}' \
          -v peer_name='${peerName}' \
          '
            $1 == peer_key {
              found = 1
              printf "johto_wireguard_peer_latest_handshake_timestamp_seconds{peer=\"%s\"} %s\n", peer_name, $5
              printf "johto_wireguard_peer_receive_bytes_total{peer=\"%s\"} %s\n", peer_name, $6
              printf "johto_wireguard_peer_transmit_bytes_total{peer=\"%s\"} %s\n", peer_name, $7
            }
            END {
              if (!found) exit 1
            }
          ' > "$temporary"

        chmod 0644 "$temporary"
        mv "$temporary" "$output"
      '';
    };

    makePeer = _: node:
      {
        allowedIPs = ["${node.address}/32"];
        persistentKeepalive = 25;
        inherit (node) publicKey;
      }
      // lib.optionalAttrs (node ? endpoint) {inherit (node) endpoint;};
  in {
    sops.secrets.wireguard-johto-private = {
      sopsFile = self + "/secrets/wireguard-johto.yaml";
      key = hostName;
      mode = "0400";
    };

    networking = {
      firewall = {
        allowedUDPPorts = [51820];
        trustedInterfaces = lib.mkBefore ["johto"];
      };

      wireguard.interfaces.johto = {
        ips = ["${currentNode.address}/24"];
        listenPort = 51820;
        privateKeyFile = config.sops.secrets.wireguard-johto-private.path;
        postSetup = ''
          ${resolvectl} dns johto 10.254.2.2
          ${resolvectl} domain johto ~johto
          ${resolvectl} default-route johto false
        '';
        peers = lib.mapAttrsToList makePeer peerNodes;
      };
    };

    services.resolved.enable = true;
    systemd.services.wireguard-johto.after = ["systemd-resolved.service"];

    systemd.services.johto-wireguard-metrics = {
      description = "Publish WireGuard peer metrics";
      after = ["wireguard-johto.service" "systemd-tmpfiles-setup.service"];
      requires = ["wireguard-johto.service"];
      serviceConfig.Type = "oneshot";
      script = "${lib.getExe wireguardMetrics}";
    };

    systemd.timers.johto-wireguard-metrics = {
      description = "Publish WireGuard peer metrics every 30 seconds";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "30s";
      };
    };
  };
}
