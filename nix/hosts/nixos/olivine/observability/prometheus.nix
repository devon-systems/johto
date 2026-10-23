_: {
  flake.nixosModules.olivine = _: {
    services.prometheus = {
      enable = true;
      port = 3020;
      retentionTime = "30d";
      extraFlags = ["--web.enable-remote-write-receiver"];
      globalConfig = {
        scrape_interval = "30s";
        evaluation_interval = "30s";
      };
      scrapeConfigs = map (scrape:
        scrape
        // {
          relabel_configs =
            (scrape.relabel_configs or [])
            ++ [
              {
                target_label = "cluster";
                replacement = "johto";
              }
            ];
        }) [
        {
          job_name = "loki";
          static_configs = [
            {
              targets = ["127.0.0.1:3030"];
              labels = {
                instance = "olivine";
                host = "olivine";
                os = "linux";
              };
            }
          ];
        }
        {
          job_name = "prometheus";
          static_configs = [
            {
              targets = ["127.0.0.1:3020"];
              labels = {
                instance = "olivine";
                host = "olivine";
                os = "linux";
              };
            }
          ];
        }
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
              targets = ["goldenrod.johto:9633"];
              labels = {
                instance = "goldenrod";
                host = "goldenrod";
                os = "linux";
              };
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
              labels = {
                instance = "goldenrod";
                host = "goldenrod";
                os = "linux";
              };
            }
            {
              targets = ["olivine.johto:3021"];
              labels = {
                instance = "olivine";
                host = "olivine";
                os = "linux";
              };
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
