_: {
  flake.nixosModules.olivine = {config, ...}: {
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
