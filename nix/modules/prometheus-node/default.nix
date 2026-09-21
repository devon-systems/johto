_: {
  flake.nixosModules.prometheusNode = {
    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = ["systemd" "textfile"];
      extraFlags = ["--collector.textfile.directory=/var/lib/johto-metrics"];
      port = 3021;
    };

    systemd.tmpfiles.rules = ["d /var/lib/johto-metrics 0755 root root -"];
  };
}
