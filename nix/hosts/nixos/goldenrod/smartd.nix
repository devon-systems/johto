_: {
  flake.nixosModules.goldenrod = {
    services = {
      smartd.enable = true;
      prometheus.exporters.smartctl = {
        enable = true;
        maxInterval = "5m";
        extraFlags = ["--smartctl.powermode-check=standby"];
      };
    };
  };
}
