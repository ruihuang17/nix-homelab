{
  ...
}:
# satsuma's NFS exports, mounted from the desktop. Kept out of the generated
# hardware-configuration.nix so a re-scan does not lose them.
#
# Mount points mirror the server paths: satsuma:/hdd/data -> ~/NAS/hdd/data,
# satsuma:/ssd/photos -> ~/NAS/ssd/photos.
let
  homelab = import ../../../homelab.nix;

  nfsOptions = [
    "noatime"
    "hard"
    "_netdev"
    "nofail"
    "x-systemd.automount"
    "x-systemd.idle-timeout=10min"
    "x-systemd.mount-timeout=30s"
  ];

  mount = path: {
    name = "/home/rhuang/NAS${path}";
    value = {
      device = "${homelab.ip "satsuma"}:${path}";
      fsType = "nfs4";
      options = nfsOptions;
    };
  };
in
{
  fileSystems = builtins.listToAttrs (
    map mount [
      "/hdd/backup"
      "/hdd/data"
      "/hdd/mediaSrv"
      # NVMe datasets: career-ops checkout (zpool/data) and the photo library
      # (zpool/photos).
      "/ssd/data"
      "/ssd/photos"
    ]
  );
}
