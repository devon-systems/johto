_: {
  flake.nixosModules.goldenrod = _: let
    logs = "/mnt/Data/apps/plex/Library/Application Support/Plex Media Server/Logs";
  in {
    networking.firewall = {
      allowedTCPPorts = [32400];
      allowedUDPPorts = [1900 32410 32412 32413 32414];
    };
    environment.etc."alloy/plex.alloy".text = ''
      local.file_match "plex" {
        path_targets = [{
          __path__ = "${logs}/Plex Media Server.log",
          job = "plex",
          service_name = "plex",
          cluster = "johto",
          host = "goldenrod",
          node = "goldenrod",
        }]
      }
      loki.source.file "plex" {
        targets = local.file_match.plex.targets
        forward_to = [loki.process.plex.receiver]
        tail_from_end = true
      }
      loki.process "plex" {
        stage.multiline {
          firstline = `^[A-Z][a-z]{2} \d{2}, \d{4} `
          max_lines = 128
          max_wait_time = "3s"
        }
        stage.regex {
          expression = `^(?P<timestamp>[A-Z][a-z]{2} \d{2}, \d{4} \d{2}:\d{2}:\d{2}\.\d{3})`
        }
        stage.timestamp {
          source = "timestamp"
          format = "Jan 02, 2006 15:04:05.000"
          location = "America/New_York"
          action_on_failure = "skip"
        }
        forward_to = [loki.process.redact.receiver]
      }
    '';
  };
}
