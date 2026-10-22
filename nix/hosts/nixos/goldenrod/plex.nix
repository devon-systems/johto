_: {
  flake.nixosModules.goldenrod = {pkgs, ...}: let
    logs = "/mnt/Data/apps/plex/Library/Application Support/Plex Media Server/Logs";
    hama = pkgs.fetchFromGitHub {
      owner = "ZeroQI";
      repo = "Hama.bundle";
      rev = "2250fabb1dbc6d3209baa204e308b2d0fb239029";
      hash = "sha256-hK4QZbl5ddHnMAE30RB8wIWQ4edvD09mgC10+Fy/R/I=";
    };
    audnexus = pkgs.fetchFromGitHub {
      owner = "djdembeck";
      repo = "Audnexus.bundle";
      rev = "4d204bf387e1a6ae844ebd2cc73b61db7540c11e";
      hash = "sha256-n+iKjhr1qAhSOfPiugUICmy3jieMc2VYycBP3V9bs7U=";
    };
    absolute = pkgs.fetchFromGitHub {
      owner = "ZeroQI";
      repo = "Absolute-Series-Scanner";
      rev = "a72a58f764d1884a3007811576440a6cf3b7f21a";
      hash = "sha256-u3MMV5YAKwfQd6XtU3XaDkxY8Hg0iZ9uWzS7Gmkx/E0=";
    };
    extensions = pkgs.runCommand "plex-extensions" {} ''
      mkdir -p "$out/Plug-ins" "$out/Scanners/Series" "$out/Scanners/Music"
      cp -R ${hama} "$out/Plug-ins/Hama.bundle"
      cp -R ${audnexus} "$out/Plug-ins/Audnexus.bundle"
      cp '${absolute}/Scanners/Series/Absolute Series Scanner.py' "$out/Scanners/Series/"
    '';
  in {
    environment.etc."plex-extensions".source = extensions;
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
        tail_from_end = false
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
