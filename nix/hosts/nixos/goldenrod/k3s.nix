{inputs, ...}: {
  flake.nixosModules.goldenrod = {pkgs, ...}: let
    hydrant = pkgs.callPackage (inputs.hydrant + "/default.nix") {};
    hydrantImage = pkgs.dockerTools.buildLayeredImage {
      name = "localhost/johto/hydrant";
      tag = inputs.hydrant.shortRev;
      contents = [pkgs.cacert];
      config = {
        Entrypoint = ["${hydrant}/bin/hydrant"];
        Env = ["SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"];
        User = "65532:65532";
      };
    };
  in {
    # The agent uses a custom data directory, including for air-gap image imports.
    systemd.tmpfiles.rules = [
      "d /var/lib/rancher/k3s-johto/agent/images 0755 root root -"
      "L+ /var/lib/rancher/k3s-johto/agent/images/hydrant.tar.gz - - - - ${hydrantImage}"
    ];
    services.k3s = {
      role = "agent";
      serverAddr = "https://10.254.2.2:6443";
      nodeLabel = ["johto.narwhal-snapper-ts.net/workload=media"];

      extraFlags = [
        "--data-dir=/var/lib/rancher/k3s-johto"
        "--node-ip=10.254.2.3"
      ];
    };
  };
}
