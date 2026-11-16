{ pkgs, ... }:
# Declarative Thunderbird account setup for Rui's desktop.
#
# Thunderbird has no NixOS account options, so this creates a dedicated,
# Nix-managed profile and links dots/thunderbird/user.js into it. `user.js` is
# read at every startup and takes precedence over the profile's mutable
# `prefs.js`, so the account definitions stay reproducible. tangerine uses the
# same files (hosts/tangerine/thunderbird.nix).
#
# Accounts:
#   - r232huan@uwaterloo.ca  (Microsoft 365, OAuth2 through Thunderbird)
#   - rui@estrogenuinely.ca  (Stalwart, normal password, kanidm name `rhuang`)
#   - rui.huang17@hotmail.com (Outlook.com, OAuth2 through Thunderbird)
# All three mirror the accounts the agent uses over IMAP.
#
# Credentials are deliberately NOT in Nix. On first launch Thunderbird prompts
# for the Stalwart password and opens the Microsoft login for the UWaterloo
# and Outlook.com accounts; all are stored in the profile afterwards.
# Thunderbird cannot read a password from a file, so an age secret cannot feed it.
let
  homelab = import ../../../homelab.nix;
  profileDir = "/home/rhuang/.thunderbird/homelab";
in
{
  # The profile directory is writable by Thunderbird; only user.js is managed.
  systemd.tmpfiles.rules = [
    "d /home/rhuang/.thunderbird 0700 rhuang rhuang -"
    "d ${profileDir} 0700 rhuang rhuang -"
    "L+ ${profileDir}/user.js - - - - ${homelab.thunderbird.userJs}"
  ];

  # profiles.ini must be writable by Thunderbird, so copy it on activation and
  # keep `homelab` as the default profile. Plain `thunderbird` then opens the
  # Nix-managed profile; the launcher is only a fallback.
  system.activationScripts.thunderbirdDefaultProfile.text = ''
    install -d -m 0700 -o rhuang -g rhuang /home/rhuang/.thunderbird
    install -m 0644 -o rhuang -g rhuang ${homelab.thunderbird.profilesIni} /home/rhuang/.thunderbird/profiles.ini
  '';

  environment.systemPackages = [
    # Thunderbird's normal profile(s) stay untouched. The profile above is the
    # default, so the launcher is normally unnecessary.
    (pkgs.writeShellScriptBin "thunderbird-homelab" ''
      exec ${pkgs.thunderbird}/bin/thunderbird -profile "$HOME/.thunderbird/homelab" "$@"
    '')
  ];
}
