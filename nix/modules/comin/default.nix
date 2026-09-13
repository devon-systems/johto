{inputs, ...}: {
  flake.nixosModules.comin = {...}: {
    imports = [inputs.comin.nixosModules.comin];

    services.comin = {
      enable = true;

      remotes = [
        {
          name = "origin";
          url = "https://github.com/devon-systems/johto.git";
          branches.main.name = "master";
          poller.period = 600;
        }
      ];
    };
  };
}
