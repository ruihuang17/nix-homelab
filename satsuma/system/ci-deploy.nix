{ pkgs, ... }:
# Lets the GitHub Actions deploy workflow (.github/workflows/deploy.yml) reach
# satsuma over Tailscale. The key is locked to one command: it cannot open a
# shell, forward ports or run anything else, so a leaked CI secret can only
# trigger a deploy of what is already on origin/main.
let
  deploy = pkgs.writeShellScript "ci-deploy" ''
    set -euo pipefail
    export PATH=/run/current-system/sw/bin:${pkgs.git}/bin:$PATH
    export HOME=/root
    export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i /root/.ssh/general -o IdentitiesOnly=yes"
    cd /etc/nixos
    git pull --ff-only origin main
    exec scripts/deploy.sh satsuma bergamot
  '';
in
{
  users.users.root.openssh.authorizedKeys.keys = [
    ''restrict,command="${deploy}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINHx3TaRusIamzqssgicuWi1rpfouY7q8ezuvjAtDqXv github-actions-deploy''
  ];
}
