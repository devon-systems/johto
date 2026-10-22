_: {
  flake.nixosModules.goldenrod = {
    fileSystems = {
      "/mnt/Data" = {
        device = "/dev/disk/by-id/ata-CT4000BX500SSD1_2447E9959972";
        fsType = "btrfs";
        options = ["compress=zstd" "noatime" "nofail"];
      };

      "/mnt/Media" = {
        device = "/dev/disk/by-id/ata-ST14000NM001G-2KJ103_ZL201XNJ-part1";
        fsType = "btrfs";
        options = ["subvol=@media" "compress=zstd" "noatime" "nofail"];
      };
    };

    myNixOs.profile.b2media = {
      cacheDir = "/mnt/Data/cache/rclone";
      audioCacheSize = "50G";
      audioReadAhead = "3G";
      videoCacheSize = "300G";
      videoReadAhead = "5G";
    };

    systemd.tmpfiles.rules = [
      "d /mnt/Data/apps 0755 root root - -"
      "d /mnt/Data/apps/albyhub 0755 root root - -"
      "d /mnt/Data/apps/audiobookshelf 0755 root root - -"
      "d /mnt/Data/apps/audiobookshelf/config 0755 root root - -"
      "d /mnt/Data/apps/audiobookshelf/metadata 0755 root root - -"
      "d /mnt/Data/apps/forgejo 0755 root root - -"
      "d /mnt/Data/apps/qbittorrent 0750 888 888 - -"
      "d /mnt/Data/apps/seerr 0755 1000 1000 - -"
      "d /mnt/Data/apps/tautulli 0700 1000 100 - -"
      "z /mnt/Data/apps/tautulli/config.ini 0600 1000 100 - -"
      "z /mnt/Data/apps/tautulli/tautulli.db 0600 1000 100 - -"
      "d /mnt/Data/apps/jellyfin 0755 root root - -"
      "d /mnt/Data/cache 0755 root root - -"
      "d /mnt/Data/cache/jellyfin 0755 root root - -"
      "d /mnt/Data/cache/plex 0755 1000 1000 - -"
      "d /mnt/Data/cache/plex-plugin-support 0755 1000 1000 - -"
      "d /mnt/Data/cache/tautulli 0700 1000 100 - -"
      "d /mnt/Data/user 0755 root root - -"
      "d /mnt/Data/legacy 0755 root root - -"
      "z /mnt/Media/Downloads 2775 - 100 - -"
      "z /mnt/Media/Anime 2775 - 100 - -"
      "z /mnt/Media/Shows 2775 - 100 - -"
      "z /mnt/Media/Movies 2775 - 100 - -"
      "z /mnt/Media/Music 2775 - 100 - -"
    ];
  };
}
