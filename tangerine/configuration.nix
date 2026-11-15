# tangerine: MacBook Pro (aarch64-darwin), Rui's laptop.
{ ... }:
{
  imports = [
    ../common-darwin.nix
    ./packages.nix
  ];

  networking.hostName = "tangerine";
  networking.computerName = "tangerine";

  # The rest of rhuang's account comes from common-darwin.nix.
  users.users.rhuang.uid = 501;

  # Touch ID for sudo. nix-darwin writes /etc/pam.d/sudo_local, which survives
  # macOS updates; the hand-written copy is kept as sudo_local.before-nix-darwin.
  security.pam.services.sudo_local.touchIdAuth = true;
}
