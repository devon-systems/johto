{
  inputs,
  self,
  ...
}: {
  config = {
    flake.nixosConfigurations.goldenrod = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        inputs.determinate.nixosModules.default
        inputs.disko.nixosModules.disko
        inputs.sops-nix.nixosModules.sops
        self.nixosModules.alloy
        self.nixosModules.aly
        self.nixosModules.b2media
        self.nixosModules.backups
        self.nixosModules.autoUpgrade
        self.nixosModules.comin
        self.nixosModules.default
        self.nixosModules.goldenrod
        self.nixosModules.k3s
        self.nixosModules.lanzaboote
        self.nixosModules.prometheusNode
        self.nixosModules.tailscale
        self.nixosModules.wireguardJohto
      ];

      specialArgs = {inherit self;};
    };

    blzrd.nodes.goldenrod = {
      output = self.nixosConfigurations.goldenrod.config.system.build.toplevel;
      type = "nixos";
      user = "root";
    };
  };
}
