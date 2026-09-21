_: {
  flake.nixosModules.olivine = {config, ...}: {
    services.k3s = {
      role = "server";
      clusterInit = true;
      nodeLabel = ["johto.narwhal-snapper-ts.net/workload=ingress"];

      extraFlags = [
        "--node-ip=10.254.2.2"
        "--advertise-address=10.254.2.2"
      ];
    };

    services.restic.backups.k3s = {
      paths = [
        "/var/lib/rancher/k3s/server/db/snapshots"
        "/var/lib/rancher/k3s/server/cred"
        "/var/lib/rancher/k3s/server/tls"
      ];
      repository = "rclone:b2:aly-backups/johto/olivine/k3s";
      backupPrepareCommand = "${config.services.k3s.package}/bin/k3s etcd-snapshot save";
      extraBackupArgs = ["--cleanup-cache"];
      initialize = true;
      passwordFile = config.sops.secrets.restic-password.path;
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
      ];
      rcloneConfigFile = config.sops.secrets.rclone-b2.path;
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "3h";
      };
    };

    services.restic.backups.uptime-kuma = {
      paths = ["/var/lib/uptime-kuma"];
      repository = "rclone:b2:aly-backups/johto/olivine/uptime-kuma";
      extraBackupArgs = ["--cleanup-cache" "--compression max" "--no-scan"];
      initialize = true;
      passwordFile = config.sops.secrets.restic-password.path;
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
      ];
      rcloneConfigFile = config.sops.secrets.rclone-b2.path;
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "3h";
      };
    };

    systemd.tmpfiles.rules = ["d /var/lib/uptime-kuma 0755 root root -"];
  };
}
