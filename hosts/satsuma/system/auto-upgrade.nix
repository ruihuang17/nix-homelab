{
  pkgs,
  ...
}:
# Daily flake update plus the push that keeps origin/main in sync.
{
  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos/#satsuma";
    # `--upgrade` is a no-op for flakes; inputs are bumped in preStart below.
    upgrade = false;
    flags = [
      "--print-build-logs"
    ];
    dates = "04:00";
    randomizedDelaySec = "45min";
    allowReboot = false; # Set to true if you want automatic reboots
  };

  systemd.services.nixos-upgrade.environment.GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh -i /root/.ssh/general -o IdentitiesOnly=yes";

  # Fast-forward to origin/main first so the lock bump commit lands on top of
  # it and can be pushed. If the branch has diverged, keep the local tree and
  # let the push step below skip.
  systemd.services.nixos-upgrade.preStart = ''
    cd /etc/nixos
    if git fetch --quiet origin main; then
      git merge --ff-only --quiet origin/main || echo "nixos-upgrade: local main has diverged from origin/main, not syncing"
    fi
    nix flake update --flake /etc/nixos --commit-lock-file
  '';

  # After the upgrade, push the flake.lock bump back to origin so the GitHub
  # repo stays in sync with the live system. Non-fatal: a push failure
  # (e.g. transient network) must not fail the already-applied upgrade.
  systemd.services.nixos-upgrade.serviceConfig.ExecStartPost =
    "-${pkgs.writeShellScript "nixos-upgrade-push" ''
      set -u
      export HOME=/root
      cd /etc/nixos || exit 0
      ${pkgs.git}/bin/git fetch --quiet origin main || exit 0
      # Only push if the local branch is strictly ahead of origin/main.
      ${pkgs.git}/bin/git merge-base --is-ancestor origin/main HEAD || exit 0
      if [ "$(${pkgs.git}/bin/git rev-list --count origin/main..HEAD)" -gt 0 ]; then
        ${pkgs.git}/bin/git push origin HEAD:main
      fi
    ''}";
}
