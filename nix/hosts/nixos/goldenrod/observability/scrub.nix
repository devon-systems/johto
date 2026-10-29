{inputs, ...}: {
  flake.nixosModules.goldenrod = {pkgs, ...}: {
    systemd.services.johto-scrub-metrics = {
      description = "Publish Btrfs device errors and completed scrub results";
      after = ["systemd-tmpfiles-setup.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${inputs.dvnpkgs.packages.${pkgs.stdenv.hostPlatform.system}.btrfs-metrics}/bin/btrfs-metrics --directory /var/lib/johto-metrics";
        ProtectSystem = "strict";
        ReadWritePaths = ["/var/lib/johto-metrics"];
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };
    systemd.timers.johto-scrub-metrics = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "5m";
      };
    };
  };
}
