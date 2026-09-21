_: {
  flake.nixosModules.goldenrod = {pkgs, ...}: {
    systemd.services.johto-scrub-metrics = {
      description = "Publish existing Btrfs scrub results";
      after = ["systemd-tmpfiles-setup.service"];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.python3}/bin/python3 <<'PY'
        from pathlib import Path
        import os
        import tempfile
        directory = Path('/var/lib/johto-metrics')
        for record in Path('/var/lib/btrfs').glob('scrub.status.*'):
            for line in record.read_text().splitlines():
                if '|' not in line:
                    continue
                identity, *fields = line.split('|')
                filesystem, device = identity.split(':')
                values = dict(field.split(':', 1) for field in fields)
                finished = values.get('finished') == '1'
                canceled = values.get('canceled') == '1'
                if not (finished or canceled):
                    continue
                errors = sum(int(value) for key, value in values.items() if key.endswith('_errors'))
                labels = f'filesystem="{filesystem}",device="{device}"'
                completion = int(values['t_start']) + int(values.get('duration', 0))
                with tempfile.NamedTemporaryFile(mode='w', dir=directory, delete=False) as output:
                    output.write(f'johto_btrfs_scrub_completion_timestamp_seconds{{{labels}}} {completion}\n')
                    output.write(f'johto_btrfs_scrub_success{{{labels}}} {int(finished and not canceled and errors == 0)}\n')
                    output.write(f'johto_btrfs_scrub_errors{{{labels}}} {errors}\n')
                    os.fchmod(output.fileno(), 0o644)
                os.replace(output.name, directory / f'scrub-{filesystem}-{device}.prom')
        PY
      '';
    };
    systemd.timers.johto-scrub-metrics = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "1m";
      };
    };
  };
}
