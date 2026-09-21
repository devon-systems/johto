_: {
  flake.nixosModules.backups = {
    config,
    lib,
    pkgs,
    ...
  }: let
    jobs = builtins.attrNames config.services.restic.backups;
    directory = "/var/lib/johto-metrics";
    reporter = pkgs.writeShellApplication {
      name = "johto-backup-metrics";
      runtimeInputs = [pkgs.coreutils pkgs.util-linux pkgs.gawk pkgs.systemd];
      text = ''
        job="$1"
        action="''${2:-complete}"
        mkdir -p ${directory}
        exec 9>"${directory}/$job.lock"
        flock 9
        output="${directory}/$job.prom"
        pending="${directory}/$job.running"
        if [ "$action" = start ]; then
          touch "$pending"
          exit 0
        fi
        success=NaN
        completed=NaN
        previous=NaN
        if [ -f "$output" ]; then
          previous=$(awk '/^johto_backup_last_success_timestamp_seconds\{/ {print $NF}' "$output")
        fi
        if [ "$action" = seed ]; then
          if [ -f "$pending" ]; then
            success=0
            completed=$(date +%s)
          elif [ -f "$output" ]; then
            exit 0
          elif [ "$(systemctl show "restic-backups-$job" -p ExecMainExitTimestampMonotonic --value)" != 0 ]; then
            state=$(systemctl show "restic-backups-$job" -p ActiveState --value)
            if [ "$state" = inactive ] || [ "$state" = failed ]; then
              completed=$(date -d "$(systemctl show "restic-backups-$job" -p ExecMainExitTimestamp --value)" +%s)
              success=0
              if [ "$(systemctl show "restic-backups-$job" -p Result --value)" = success ] &&
                 [ "$(systemctl show "restic-backups-$job" -p ExecMainCode --value)" = 1 ] &&
                 [ "$(systemctl show "restic-backups-$job" -p ExecMainStatus --value)" = 0 ]; then
                success=1
              fi
            fi
          fi
        else
          completed=$(date +%s)
          success=0
          if [ "''${SERVICE_RESULT:-}" = success ] && [ "''${EXIT_CODE:-}" = exited ] && [ "''${EXIT_STATUS:-}" = 0 ]; then
            success=1
          fi
        fi
        if [ "$success" = 1 ]; then previous="$completed"; fi
        temporary=$(mktemp "${directory}/$job.XXXXXX")
        trap 'rm -f "$temporary"' EXIT
        {
          printf 'johto_backup_job_info{backup="%s"} 1\n' "$job"
          printf 'johto_backup_last_completion_timestamp_seconds{backup="%s"} %s\n' "$job" "$completed"
          printf 'johto_backup_last_success_timestamp_seconds{backup="%s"} %s\n' "$job" "$previous"
          printf 'johto_backup_last_run_success{backup="%s"} %s\n' "$job" "$success"
        } > "$temporary"
        chmod 644 "$temporary"
        mv "$temporary" "$output"
        rm -f "$pending"
      '';
    };
  in {
    systemd.services =
      lib.listToAttrs (map (job: {
          name = "restic-backups-${job}";
          value.serviceConfig = {
            ExecStartPre = lib.mkBefore ["-${lib.getExe reporter} ${lib.escapeShellArg job} start"];
            ExecStopPost = lib.mkAfter ["-${lib.getExe reporter} ${lib.escapeShellArg job}"];
          };
        })
        jobs)
      // {
        johto-backup-metrics-seed = {
          description = "Seed backup inventory and completed systemd results";
          wantedBy = ["multi-user.target"];
          after = ["systemd-tmpfiles-setup.service"];
          before = map (job: "restic-backups-${job}.service") jobs;
          serviceConfig.Type = "oneshot";
          script = lib.concatMapStringsSep "\n" (job: "${lib.getExe reporter} ${lib.escapeShellArg job} seed || true") jobs;
        };
      };
  };
}
