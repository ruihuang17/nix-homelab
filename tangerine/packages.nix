{ lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    macshot 
    vlc-bin
    bitwarden-desktop
    wechat
    vesktop
    kitty-bin
  ];

  homebrew = {
    enable = true;
    user = "rhuang";

    onActivation.cleanup = "none";
    onActivation.autoUpdate = false;
    onActivation.upgrade = false;

    casks = [
      "firefox"
      "claude-code@latest"
    ];

    brews = [

    ];
  };
}
