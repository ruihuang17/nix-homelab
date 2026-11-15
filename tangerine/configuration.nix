{
  config,
  lib,
  pkgs,
  ...
}:
let
  homelab = import ../homelab.nix;
in
{
  imports = [
    ../common-darwin.nix
  ];

  # nix-darwin's own state marker (unrelated to system.stateVersion on NixOS).
  system.stateVersion = 7;

  # Required by launchd.user.agents: nix-darwin writes the plists into this
  # user's ~/Library/LaunchAgents and loads them with `launchctl asuser`.
  system.primaryUser = "rhuang";

  # allowUnfree and experimental-features come from common-darwin.nix.
  nix.settings.trusted-users = [
    "root"
    "rhuang"
  ];
  nix.optimise.automatic = true;
  nix.optimise.interval = [
    {
      Hour = 5;
      Minute = 0;
    }
  ];

  networking.hostName = "tangerine";
  networking.computerName = "tangerine";
  time.timeZone = "America/Toronto";

  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  # NOTE: users.knownUsers makes nix-darwin own this account. Removing the
  # users.users.rhuang block below would make the next activation delete the
  # user. Keep both or neither.
  users.knownUsers = [ "rhuang" ];
  users.users.rhuang = {
    uid = 501;
    gid = 20;
    home = "/Users/rhuang";
    shell = pkgs.fish;
  };

  # NFS media access is granted by GID 3000, not by UID: satsuma exports
  # /hdd/mediaSrv as root:media (GID 3000) mode 770. macos sends numeric
  # AUTH_SYS IDs over NFSv3, so rhuang must be in the local storage group.
  # Without this Jellyfin gets EACCES and playback stops at 0 ms.
  users.knownGroups = [ "storage" ];
  users.groups.storage = {
    gid = homelab.storageGid;
    description = "Storage Access Group";
    members = [ "rhuang" ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    tmux
    btop
    tree
    ripgrep
    fd
    jq
    wget
  ];

}
