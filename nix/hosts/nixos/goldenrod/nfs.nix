_: {
  flake.nixosModules.goldenrod = {
    services.nfs.server = {
      enable = true;
      exports = ''
        /mnt/Data 127.0.0.1(rw,sync,no_subtree_check,no_root_squash,fsid=0) 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash,fsid=0) 10.254.2.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=0)
        /mnt/Media 127.0.0.1(rw,sync,no_subtree_check,no_root_squash,fsid=1) 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash,fsid=1) 10.254.2.0/24(rw,sync,no_subtree_check,no_root_squash,fsid=1)
      '';
    };
  };
}
