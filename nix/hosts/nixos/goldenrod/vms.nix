_: {
  flake.nixosModules.goldenrod = {
    config,
    pkgs,
    self,
    ...
  }: {
    sops.secrets.cherrygrove-tailscale-auth-key = {
      key = "tailscale-auth-key";
      sopsFile = self + "/secrets/tailscale.yaml";
    };
    sops.secrets.cherrygrove-aly-password = {
      key = "aly-password";
      sopsFile = self + "/secrets/aly-password.yaml";
    };

    systemd.services.cherrygrove-secrets = {
      before = ["microvm@cherrygrove.service"];
      requiredBy = ["microvm@cherrygrove.service"];

      serviceConfig = {
        RemainAfterExit = true;
        RuntimeDirectory = "cherrygrove-secrets";
        RuntimeDirectoryMode = "0750";
        Type = "oneshot";
      };

      script = ''
        ${pkgs.coreutils}/bin/install -m 0440 \
          ${config.sops.secrets.cherrygrove-tailscale-auth-key.path} \
          "$RUNTIME_DIRECTORY/tailscale-auth-key"
        ${pkgs.coreutils}/bin/install -m 0400 \
          ${config.sops.secrets.cherrygrove-aly-password.path} \
          "$RUNTIME_DIRECTORY/aly-password"
      '';
    };

    microvm = {
      host.useNotifySockets = true;
      stateDir = "/mnt/Data/microvms";

      vms.cherrygrove = {
        autostart = true;
        config = self.nixosModules.cherrygrove;
        # Host monitoring changes must not restart this VM.
        restartIfChanged = false;
        specialArgs = {inherit self;};
      };
    };

    # Keep the installed VM runner during host-only rollouts. A VM update must
    # deliberately remove this guard before replacing its current generation.
    systemd.services.install-microvm-cherrygrove.unitConfig.ConditionPathExists = "!${config.microvm.stateDir}/cherrygrove/current";

    networking = {
      firewall.trustedInterfaces = ["cherrygrove"];
      nat = {
        enable = true;
        externalInterface = "enp16s0f4u1";
        internalIPs = ["10.217.0.0/24"];
      };
    };

    systemd.network = {
      enable = true;
      networks."30-cherrygrove" = {
        matchConfig.Name = "cherrygrove";
        address = ["10.217.0.1/32"];
        routes = [{Destination = "10.217.0.2/32";}];
        networkConfig.IPv4Forwarding = true;
      };
    };
  };
}
