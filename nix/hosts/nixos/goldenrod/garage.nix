_: {
  flake.nixosModules.goldenrod = {
    config,
    lib,
    pkgs,
    self,
    ...
  }: let
    dataDirectory = "/mnt/Data/apps";
  in {
    sops.secrets = {
      garage-nextcloud-access-key = {
        sopsFile = self + "/secrets/garage.yaml";
        key = "nextcloud_access_key";
        owner = "garage";
        group = "garage";
      };

      garage-nextcloud-secret-key = {
        sopsFile = self + "/secrets/garage.yaml";
        key = "nextcloud_secret_key";
        owner = "garage";
        group = "garage";
      };

      garage-rpc-secret = {
        sopsFile = self + "/secrets/garage.yaml";
        key = "rpc_secret";
        owner = "garage";
        group = "garage";
      };
    };

    sops.templates = {
      garage-config = {
        owner = "garage";
        group = "garage";
        mode = "0400";
        restartUnits = ["garage.service"];

        content = ''
          metadata_dir = "${dataDirectory}/garage/meta"
          data_dir = "${dataDirectory}/garage/data"
          db_engine = "sqlite"
          replication_factor = 1
          rpc_bind_addr = "[::]:3901"
          rpc_public_addr = "10.254.2.3:3901"
          rpc_secret = "${config.sops.placeholder.garage-rpc-secret}"

          [s3_api]
          api_bind_addr = "[::]:3900"
          s3_region = "garage"
        '';
      };

      garage-environment = {
        owner = "garage";
        group = "garage";
        mode = "0400";

        content = ''
          GARAGE_CONFIG_FILE=${config.sops.templates.garage-config.path}
          GARAGE_DEFAULT_ACCESS_KEY=${config.sops.placeholder.garage-nextcloud-access-key}
          GARAGE_DEFAULT_SECRET_KEY=${config.sops.placeholder.garage-nextcloud-secret-key}
          GARAGE_DEFAULT_BUCKET=aly-nextcloud
        '';
      };
    };

    users = {
      groups.garage = {};

      users.garage = {
        isSystemUser = true;
        group = "garage";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${dataDirectory}/garage 0750 garage garage - -"
      "d ${dataDirectory}/garage/meta 0700 garage garage - -"
      "d ${dataDirectory}/garage/data 0700 garage garage - -"
    ];

    services.garage = {
      enable = true;
      package = pkgs.garage_2;
      environmentFile = config.sops.templates.garage-environment.path;

      settings = {
        metadata_dir = "${dataDirectory}/garage/meta";
        data_dir = "${dataDirectory}/garage/data";
      };
    };

    systemd.services.garage = {
      after = ["mnt-Data.mount"];
      requires = ["mnt-Data.mount"];
      serviceConfig = {
        # Garage reads GARAGE_DEFAULT_* only with these flags.
        ExecStart = lib.mkForce "${config.services.garage.package}/bin/garage server --single-node --default-bucket";
        DynamicUser = false;
        User = "garage";
        Group = "garage";
      };
    };
  };
}
