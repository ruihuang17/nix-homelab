{ pkgs, ... }:
# Lets the GitHub Actions deploy workflow (.github/workflows/deploy.yml) reach
# satsuma over Tailscale. The key is locked to one script: it cannot open a
# shell or forward ports. The only input it takes is a list of host names,
# checked against an allowlist below, so a leaked CI secret can only trigger a
# deploy of what is already on origin/main.
let
  deploy = pkgs.writeShellScript "ci-deploy" ''
    set -euo pipefail
    set -f # no globbing of the client-supplied host list
    export PATH=/run/current-system/sw/bin:${pkgs.git}/bin:$PATH
    export HOME=/root
    export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i /root/.ssh/general -o IdentitiesOnly=yes"

    hosts="''${SSH_ORIGINAL_COMMAND:-satsuma bergamot}"
    nixos=()
    lime=0
    for h in $hosts; do
      case $h in
        satsuma | bergamot | pomelo) nixos+=("$h") ;;
        lime) lime=1 ;;
        *) echo "ci-deploy: unknown host: $h" >&2; exit 2 ;;
      esac
    done

    cd /etc/nixos
    git pull --ff-only origin main

    rc=0
    if ((''${#nixos[@]})); then
      scripts/deploy.sh -k "''${nixos[@]}" || rc=1
    fi
    if ((lime)); then
      # nix-darwin: built on the Mac itself; rhuang has passwordless sudo there.
      ssh -o BatchMode=yes lime 'cd ~/nix-homelab && git pull --ff-only && sudo -n darwin-rebuild switch --flake .#lime' || rc=1
    fi
    exit $rc
  '';
in
{
  users.users.root.openssh.authorizedKeys.keys = [
    ''restrict,command="${deploy}" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINHx3TaRusIamzqssgicuWi1rpfouY7q8ezuvjAtDqXv github-actions-deploy''
  ];
}
