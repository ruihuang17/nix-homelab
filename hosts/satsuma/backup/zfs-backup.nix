# Local ZFS snapshot + replication backup of the NVMe pool onto the hdd pool.
#
#   sanoid  -> takes & prunes periodic snapshots of zpool/var and zpool/photos
#   syncoid -> replicates those snapshots (incrementally) to hdd/backup/{var,photos}
#
# Destination datasets are created out-of-band (not mounted: canmount=off,
# mountpoint=none) so the received copy never shadows the live dataset.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # --- Periodic snapshots (source side) -------------------------------------
  services.sanoid = {
    enable = true;

    datasets = {
      "zpool/var" = {
        useTemplate = [ "var" ];
        recursive = true;
      };

      "zpool/photos".useTemplate = [ "photos" ];

      # Destination: keep the replicated snapshots per the same retention,
      # but never take new snapshots there (syncoid pushes them in).
      "hdd/backup/var" = {
        useTemplate = [ "backup" ];
        recursive = true;
      };

      "hdd/backup/photos".useTemplate = [ "photos-backup" ];
    };

    templates = {
      var = {
        autosnap = true;
        autoprune = true;
        hourly = 36;
        daily = 14;
        weekly = 4;
        monthly = 3;
      };

      backup = {
        autosnap = false; # snapshots arrive via syncoid, don't create here
        autoprune = true; # but do prune old ones on the backup pool
        hourly = 36;
        daily = 14;
        weekly = 4;
        monthly = 3;
      };

      # Photos change rarely, so keep a longer history to recover from
      # accidental deletes or bad batch renames noticed months later.
      photos = {
        autosnap = true;
        autoprune = true;
        hourly = 24;
        daily = 30;
        weekly = 8;
        monthly = 12;
      };

      photos-backup = {
        autosnap = false;
        autoprune = true;
        hourly = 24;
        daily = 30;
        weekly = 8;
        monthly = 12;
      };
    };
  };

  # --- Replication to the hdd pool (destination side) -----------------------
  services.syncoid = {
    enable = true;

    # Run once per day.
    interval = "daily";

    # Local root->root replication; no SSH needed.
    commands."var-to-hdd" = {
      source = "zpool/var";
      target = "hdd/backup/var";
      recursive = true;
      # Reuse sanoid's snapshots instead of syncoid taking its own.
      extraArgs = [ "--no-sync-snap" ];
    };

    commands."photos-to-hdd" = {
      source = "zpool/photos";
      target = "hdd/backup/photos";
      extraArgs = [ "--no-sync-snap" ];
    };
  };
}
