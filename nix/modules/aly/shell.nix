_: {
  flake.nixosModules.aly = {pkgs, ...}: {
    users.users.aly.packages = with pkgs; [
      age
      codex
      duf
      dust
      eza
      gh
      htop
      jq
      just
      lazygit
      ripgrep
      starship
      tmux
      zoxide
    ];
  };
}
