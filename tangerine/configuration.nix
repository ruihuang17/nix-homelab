# tangerine: MacBook Pro (aarch64-darwin), Rui's laptop.
{ ... }:
{
  imports = [
    ../common-darwin.nix
  ];

  networking.hostName = "tangerine";
  networking.computerName = "tangerine";

  # The rest of rhuang's account comes from common-darwin.nix.
  users.users.rhuang.uid = 501;
}
