# lime: Apple M4 Mac mini (aarch64-darwin) - iMessage bridge + Jellyfin.
#
# Two things are deliberately NOT managed by Nix:
#   * ~/mautrix-imessage/mautrix-imessage - its TCC Full Disk Access grant is
#     bound to the binary's cdhash; a /nix/store copy would lose it.
#   * /Applications/Jellyfin.app - Homebrew cask, likewise TCC-bound.
# See docs/lime (macOS).md before moving either.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  homelab = import ../../homelab.nix;
in
{
  imports = [
    ./agents.nix
    ./homebrew.nix
    ../../common-darwin.nix
  ];

  networking.hostName = "lime";
  networking.computerName = "lime";

  # This box has to come back unattended: it is only reachable through
  # auto-login (which works because FileVault is off) and nothing reboots it by
  # hand. See docs/lime (macOS).md.
  power.sleep.computer = "never";
  power.sleep.display = "never";
  power.sleep.harddisk = "never";
  power.restartAfterPowerFailure = true;

  # mautrix-imessage's config.yaml carries the appservice as_token/hs_token.
  # agenix decrypts it into a RAM disk at boot; nothing plaintext is written
  # under the home directory or /var/lib. See hosts/lime/agents.nix for the consumer.
  age.secrets.imessage-config = {
    file = ./secrets/imessage-config.age;
    owner = "rhuang";
    group = "staff";
    mode = "0400";
  };

  # The rest of rhuang's account comes from common-darwin.nix.
  users.users.rhuang.uid = 502;

  # --- autofs: the media library ------------------------------------------
  # NFSv3 with an explicit mountport because this macOS client cannot
  # negotiate NFSv4 with satsuma; nolocks because the NLM ports are not opened
  # (Jellyfin otherwise opens a file and hangs on the first read).
  environment.etc."auto_nas".text = ''
    /Users/rhuang/NAS/mediaSrv  -fstype=nfs,nfsvers=3,proto=tcp,port=2049,mountport=20048,resvport,rw,nolocks,hard,timeo=14  ${homelab.ip "satsuma"}:/hdd/mediaSrv
  '';

  environment.etc."auto_master".text = ''
    #
    # Automounter master map - managed by nix-darwin (hosts/lime/configuration.nix).
    #
    +auto_master
    /home   auto_home   -nobrowse,hidefromfinder
    /Network/Servers  -fstab
    /-  -static
    /-  auto_nas  -nosuid,noatime
  '';

  system.activationScripts.postActivation.text = lib.mkAfter ''
    # automountd must be loaded or NFS access fails with ECONNRESET even though
    # a manual mount works (docs/NFS.md). Enabling it persists in launchd's
    # disabled.plist, so this is only a no-op after the first run.
    launchctl enable system/com.apple.automountd 2>/dev/null || true
    /usr/sbin/automount -vc >/dev/null 2>&1 || true
  '';
}
