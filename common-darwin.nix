{
  lib,
  pkgs,
  ...
}:
# nix-darwin counterpart of common-nixos.nix: the Nix settings, rhuang's
# account and the shell tooling every Mac (lime, tangerine) shares.
#
# NixOS-only options (systemd, users via activation, sshd) stay out, so this
# file is imported only by the darwin hosts. It reads homelab.nix itself, so a
# host imports this one file. Each host still sets its hostname and rhuang's
# uid, which macOS assigns at install time.
let
  homelab = import ./homelab.nix;

  # Dotfiles are linked by the activation script, run as the user so the links
  # and their parent directories get the right owner.
  dotUsers = [ "rhuang" ];
in
{
  # nix-darwin's own state marker (unrelated to system.stateVersion on NixOS).
  system.stateVersion = 7;

  # Required by launchd.user.agents: nix-darwin writes the plists into this
  # user's ~/Library/LaunchAgents and loads them with `launchctl asuser`.
  system.primaryUser = "rhuang";

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
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

  time.timeZone = "America/Toronto";

  programs.fish.enable = true;

  # Login shell: nix's fish. Homebrew's fish reads /opt/homebrew/etc/fish, so
  # nix-darwin's /etc/fish/config.fish (and therefore /run/current-system/sw/bin
  # on PATH) never applied to it. ~/.config/fish/config.fish still loads.
  environment.shells = [ pkgs.fish ];

  # NOTE: users.knownUsers makes nix-darwin own this account. Removing the
  # users.users.rhuang block below would make the next activation delete the
  # user. Keep both or neither. The uid is set per host.
  users.knownUsers = [ "rhuang" ];
  users.users.rhuang = {
    gid = 20;
    home = "/Users/rhuang";
    shell = pkgs.fish;
  };

  # NFS media access is granted by GID 3000, not by UID: satsuma exports
  # /hdd/mediaSrv as root:media (GID 3000) mode 770. macOS sends numeric
  # AUTH_SYS IDs over NFSv3, so rhuang must be in the local storage group.
  # Without this Jellyfin gets EACCES and playback stops at 0 ms. See docs/NFS.md.
  users.knownGroups = [ "storage" ];
  users.groups.storage = {
    gid = homelab.storageGid;
    description = "Storage Access Group";
    members = [ "rhuang" ];
  };

  environment.systemPackages = with pkgs; [
    starship
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

  programs.fish.interactiveShellInit = ''
    if test "$TERM" != "dumb"
      ${pkgs.starship}/bin/starship init fish | source
    end
  '';

  # The prompt uses Nerd Font glyphs. Only the Mac runs a terminal locally;
  # over SSH the font comes from the client, so the servers skip it.
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  system.activationScripts.postActivation.text = lib.mkAfter (
    lib.concatMapStrings (
      user:
      let
        home = "/Users/${user}";
        as = "sudo -u ${lib.escapeShellArg user}";
      in
      lib.concatStrings (
        lib.mapAttrsToList (rel: src: ''
          ${as} mkdir -p ${lib.escapeShellArg (dirOf "${home}/${rel}")}
          ${as} ln -sfn ${src} ${lib.escapeShellArg "${home}/${rel}"}
        '') homelab.dotfiles
      )
    ) dotUsers
  );
}
