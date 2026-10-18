_: {
  flake.nixosModules.olivine = {config, ...}: let
    metricsBackup = {
      name,
      paths,
    }: {
      inherit paths;
      repository = "rclone:b2:aly-backups/johto/olivine/${name}";
      extraBackupArgs = ["--cleanup-cache"];
      initialize = true;
      passwordFile = config.sops.secrets.restic-password.path;
      rcloneConfigFile = config.sops.secrets.rclone-b2.path;
      pruneOpts = ["--keep-daily 3" "--keep-weekly 2"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "3h";
      };
    };
  in {
    services.restic.backups = {
      loki = metricsBackup {
        name = "loki";
        paths = ["/var/lib/loki"];
      };
      prometheus = metricsBackup {
        name = "prometheus";
        paths = ["/var/lib/prometheus2"];
      };
    };
  };
}
