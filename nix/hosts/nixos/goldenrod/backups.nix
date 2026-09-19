_: {
  flake.nixosModules.goldenrod = {
    config,
    lib,
    pkgs,
    ...
  }: let
    coreRetention = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 3"
    ];
    rebuildableRetention = ["--keep-daily 7" "--keep-weekly 4"];
    metricsRetention = ["--keep-daily 3" "--keep-weekly 2"];

    appBackup = {
      name,
      paths,
      pruneOpts,
      extraBackupArgs ? ["--cleanup-cache" "--compression max" "--no-scan"],
      inhibitsSleep ? true,
      backupPrepareCommand ? null,
      backupCleanupCommand ? null,
    }:
      {
        inherit extraBackupArgs inhibitsSleep paths pruneOpts;
        initialize = true;
        passwordFile = config.sops.secrets.restic-password.path;
        rcloneConfigFile = config.sops.secrets.rclone-b2.path;
        repository = "rclone:b2:aly-backups/johto/goldenrod/${name}";
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "3h";
        };
      }
      // lib.optionalAttrs (backupPrepareCommand != null) {inherit backupPrepareCommand;}
      // lib.optionalAttrs (backupCleanupCommand != null) {inherit backupCleanupCommand;};
  in {
    services.restic.backups = {
      albyhub = appBackup {
        name = "albyhub";
        paths = ["/mnt/Data/apps/albyhub"];
        pruneOpts = coreRetention;
      };

      audiobookshelf = appBackup {
        name = "audiobookshelf";
        paths = ["/mnt/Data/apps/audiobookshelf"];
        pruneOpts = rebuildableRetention;
      };

      forgejo = appBackup {
        name = "forgejo";
        paths = ["/mnt/Data/apps/forgejo"];
        pruneOpts = coreRetention;
      };

      garage = appBackup {
        name = "garage";
        paths = ["/mnt/Data/apps/garage"];
        pruneOpts = coreRetention;
        backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop garage";
        backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start garage";
      };

      immich =
        (appBackup {
          name = "immich";
          paths = ["/mnt/Data/apps/immich"];
          pruneOpts = coreRetention;
          extraBackupArgs = ["--cleanup-cache" "--compression max" "--no-scan" "--exclude=/mnt/Data/apps/immich/postgres-johto"];
          backupPrepareCommand = ''
            set -eu
            dump=$(${pkgs.findutils}/bin/find /mnt/Data/apps/immich/backups -maxdepth 1 -name 'immich-db-backup-*.sql.gz' -type f -printf '%T@ %p\n' | ${pkgs.coreutils}/bin/sort -nr | ${pkgs.gnused}/bin/sed -n '1s/^[^ ]* //p')
            test -n "$dump"
            timestamp=$(${pkgs.coreutils}/bin/stat -c %Y "$dump")
            age=$(( $(${pkgs.coreutils}/bin/date +%s) - timestamp ))
            if [ "$age" -lt 0 ] || [ "$age" -gt 21600 ]; then
              echo "Immich database dump is older than six hours or dated in the future" >&2
              exit 1
            fi
            before=$(${pkgs.coreutils}/bin/stat -c '%i:%s:%Y' "$dump")
            ${pkgs.gzip}/bin/gzip -t "$dump"
            test "$before" = "$(${pkgs.coreutils}/bin/stat -c '%i:%s:%Y' "$dump")"
            (
            temporary=$(${pkgs.coreutils}/bin/mktemp /var/lib/johto-backup-metrics/immich-dump.XXXXXX)
            printf 'johto_immich_dump_timestamp_seconds %s\n' "$timestamp" > "$temporary"
            ${pkgs.coreutils}/bin/chmod 644 "$temporary"
            ${pkgs.coreutils}/bin/mv "$temporary" /var/lib/johto-backup-metrics/immich-dump.prom
            ) || true
          '';
        })
        // {
          timerConfig = {
            OnCalendar = "*-*-* 03:00:00 America/New_York";
            Persistent = true;
            RandomizedDelaySec = 0;
          };
        };

      k3s-local-path = appBackup {
        name = "k3s-local-path";
        paths = ["/var/lib/rancher/k3s/storage"];
        pruneOpts = coreRetention;
        extraBackupArgs = [
          "--cleanup-cache"
          "--exclude=/var/lib/rancher/k3s/storage/*_cnpg-system_pg-shared-1/**"
        ];
        inhibitsSleep = false;
      };

      loki = appBackup {
        name = "loki";
        paths = ["/var/lib/loki"];
        pruneOpts = metricsRetention;
        extraBackupArgs = ["--cleanup-cache"];
        inhibitsSleep = false;
      };

      nextcloud = appBackup {
        name = "nextcloud";
        paths = ["/mnt/Data/apps/nextcloud/html"];
        pruneOpts = coreRetention;
      };

      paperless = appBackup {
        name = "paperless";
        paths = ["/mnt/Data/apps/paperless"];
        pruneOpts = coreRetention;
      };

      plex = appBackup {
        name = "plex";
        paths = ["/mnt/Data/apps/plex"];
        pruneOpts = rebuildableRetention;
        extraBackupArgs = [
          "--cleanup-cache"
          "--compression max"
          "--no-scan"
          "--exclude=/mnt/Data/apps/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases"
        ];
      };

      prometheus = appBackup {
        name = "prometheus";
        paths = ["/var/lib/prometheus2"];
        pruneOpts = metricsRetention;
        extraBackupArgs = ["--cleanup-cache"];
        inhibitsSleep = false;
      };

      qbittorrent = appBackup {
        name = "qbittorrent";
        paths = ["/mnt/Data/apps/qbittorrent"];
        pruneOpts = rebuildableRetention;
      };

      seerr = appBackup {
        name = "seerr";
        paths = ["/mnt/Data/apps/seerr"];
        pruneOpts = rebuildableRetention;
      };

      tautulli = appBackup {
        name = "tautulli";
        paths = ["/mnt/Data/apps/tautulli"];
        pruneOpts = rebuildableRetention;
      };

      uptime-kuma = appBackup {
        name = "uptime-kuma";
        paths = ["/mnt/Data/apps/uptime-kuma"];
        pruneOpts = rebuildableRetention;
      };
    };

    services.snapper = {
      configs = {
        home = {
          ALLOW_GROUPS = ["users"];
          FSTYPE = "btrfs";
          SUBVOLUME = "/home";
          TIMELINE_CLEANUP = true;
          TIMELINE_CREATE = true;
        };

        media = {
          ALLOW_GROUPS = ["users"];
          FSTYPE = "btrfs";
          SUBVOLUME = "/mnt/Media";
          TIMELINE_CLEANUP = true;
          TIMELINE_CREATE = true;
        };
      };

      filters = ''
        -.bash_profile
        -.bashrc
        -.cache
        -.config
        -.local
        -.nix-profile
        -.pki
        -.share
        -.snapshots
        -.zshrc
      '';

      persistentTimer = true;
    };
  };
}
