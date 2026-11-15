{ lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    macshot 
    vlc-bin
    bitwarden-desktop
    wechat
    vesktop
    kitty-bin
    rbw
    pinentry_mac # rbw is configured with `pinentry = "pinentry-mac"`
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
