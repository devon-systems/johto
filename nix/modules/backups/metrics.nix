_: {
  flake.nixosModules.backups = {
    config,
    lib,
    pkgs,
    ...
  }: let
    directory = "/var/lib/johto-metrics";
    jobs = builtins.attrNames config.services.restic.backups;
    reporter = pkgs.writeShellApplication {
      name = "johto-backup-metrics";
      runtimeInputs = [pkgs.python3 pkgs.systemd pkgs.coreutils];
      text = ''exec python3 ${../../../scripts/backup-metrics.py} "$@"'';
    };
    command = "${lib.getExe reporter} --directory ${directory}";
  in {
    systemd.services = lib.mkMerge [
      (lib.mapAttrs' (job: _:
        lib.nameValuePair "restic-backups-${job}" {
          onSuccess = ["johto-backup-metrics-${job}.service"];
          onFailure = ["johto-backup-metrics-${job}.service"];
          serviceConfig.ExecStartPre = lib.mkBefore ["-${command} --start ${lib.escapeShellArg job}"];
        })
      config.services.restic.backups)
      (lib.listToAttrs (map (job:
        lib.nameValuePair "johto-backup-metrics-${job}" {
          description = "Publish completed backup result for ${job}";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${command} ${lib.escapeShellArg job}";
          };
        })
      jobs))
      {
        johto-backup-metrics-seed = {
          description = "Initialize backup inventory and recover interrupted results";
          wantedBy = ["multi-user.target"];
          after = ["systemd-tmpfiles-setup.service"];
          before = ["alloy.service"] ++ map (job: "restic-backups-${job}.service") jobs;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${command} --seed ${lib.escapeShellArgs jobs}";
          };
        };
      }
    ];
  };
}
