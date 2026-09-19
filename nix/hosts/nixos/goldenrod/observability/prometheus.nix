_: {
  flake.nixosModules.goldenrod = _: {
    services.prometheus = {
      enable = true;
      port = 3020;
      retentionTime = "30d";
      extraFlags = ["--web.enable-remote-write-receiver"];
      globalConfig = {
        scrape_interval = "30s";
        evaluation_interval = "30s";
      };
      scrapeConfigs = [
        {
          job_name = "bazarr";
          scrape_interval = "60s";
          scrape_timeout = "55s";
          static_configs = [{targets = ["bazarr.arr.svc.cluster.local:9708"];}];
        }
        {
          job_name = "lidarr";
          static_configs = [{targets = ["lidarr.arr.svc.cluster.local:9709"];}];
        }
        {
          job_name = "prowlarr";
          static_configs = [{targets = ["prowlarr.arr.svc.cluster.local:9710"];}];
        }
        {
          job_name = "radarr";
          static_configs = [{targets = ["radarr.arr.svc.cluster.local:9711"];}];
        }
        {
          job_name = "smartctl";
          static_configs = [
            {
              targets = ["127.0.0.1:9633"];
              labels.instance = "goldenrod";
            }
          ];
        }
        {
          job_name = "sonarr";
          static_configs = [{targets = ["sonarr.arr.svc.cluster.local:9712"];}];
        }
        {
          job_name = "node";
          static_configs = [
            {
              targets = ["goldenrod.johto:3021"];
              labels.instance = "goldenrod";
            }
            {
              targets = ["olivine.johto:3021"];
              labels.instance = "olivine";
            }
          ];
        }
      ];
    };

    services.resolved.settings.Resolve = {
      DNS = ["10.43.0.10"];
      Domains = ["~svc.cluster.local"];
    };
  };
}
