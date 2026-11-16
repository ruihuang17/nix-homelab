{ lib, ... }:
# Thunderbird on the laptop, with the same Nix-managed `homelab` profile and
# accounts as pomelo (see hosts/pomelo/modules/thunderbird.nix). The app itself
# is the `thunderbird` cask in packages.nix.
#
# macOS keeps profiles under ~/Library/Thunderbird. user.js is linked from the
# store; profiles.ini is copied because Thunderbird rewrites it.
let
  homelab = import ../../homelab.nix;
  base = "/Users/rhuang/Library/Thunderbird";
  as = "sudo -u rhuang";
in
{
  system.activationScripts.postActivation.text = lib.mkAfter ''
    ${as} mkdir -p ${base}/homelab
    chmod 700 ${base} ${base}/homelab
    ${as} ln -sfn ${homelab.thunderbird.userJs} ${base}/homelab/user.js
    ${as} install -m 0644 ${homelab.thunderbird.profilesIni} ${base}/profiles.ini
  '';
}
