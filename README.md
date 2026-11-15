# nixos-homelab

One flake for the whole homelab: three NixOS machines, two macOS machines, and
the packages/services that tie them together.

| Host | Config | Platform | Address | Role |
| --- | --- | --- | --- | --- |
| `satsuma` | `satsuma/` | NixOS (unstable) | `10.0.10.72` | Main server: storage, nginx, Kanidm, Nextcloud, Matrix, media, monitoring, AI |
| `bergamot` (hostname `mail`) | `bergamot/` | NixOS (unstable) | `100.91.236.114` (Tailscale) | OVH VPS: Stalwart mail server, offsite backups |
| `pomelo` | `pomelo/` | NixOS (unstable) | `10.0.10.40` | Desktop |
| `lime` | `lime/` | nix-darwin (aarch64) | `10.0.10.73` | Mac mini: iMessage bridge, digest service, Jellyfin |
| `tangerine` | `tangerine/` | nix-darwin (aarch64) | `10.0.10.41` | MacBook Pro laptop |

See [docs/Setup Overview.md](docs/Setup%20Overview.md) for hardware and the full
service inventory, and [docs/IP Address.md](docs/IP%20Address.md) for the rest of
the LAN.

## Applying changes

`scripts/deploy.sh` runs `nixos-rebuild` for one or more NixOS hosts from this
checkout. Remote hosts are reached through the ssh aliases the flake installs
(`root@bergamot`, `rhuang@pomelo` with sudo); the host you are on is switched
locally.

```sh
scripts/deploy.sh                # satsuma, bergamot, pomelo
scripts/deploy.sh bergamot pomelo  # a selection
scripts/deploy.sh -b all         # build only, no activation
scripts/deploy.sh -n all         # print the commands without running them
scripts/deploy.sh -k all         # keep going if one host fails
```

`lime` and `tangerine` are nix-darwin and cannot be deployed from Linux;
`scripts/deploy.sh lime` (or `tangerine`) prints the command to run on the Mac. The manual equivalents:

```sh
# satsuma (also the canonical checkout at /etc/nixos)
sudo nixos-rebuild switch --flake /etc/nixos#satsuma

# bergamot, from satsuma
sudo nixos-rebuild switch --flake /etc/nixos#bergamot --target-host root@bergamot

# pomelo
sudo nixos-rebuild switch --flake /etc/nixos#pomelo

# lime / tangerine (on the Mac)
sudo darwin-rebuild switch --flake ~/nixos-homelab#lime
sudo darwin-rebuild switch --flake ~/nixos-homelab#tangerine
```

To verify without switching, add `build` instead of `switch`. satsuma
auto-upgrades daily at 04:00, commits `flake.lock` and pushes it to `main`; if
you are holding a change back, stop `nixos-upgrade.timer` first.

## Layout

```
.
├── flake.nix              # inputs + the five host configurations
├── homelab.nix            # data: addresses, users/keys, GID, domain, dotfiles
├── common-nixos.nix       # every NixOS host
├── common-darwin.nix      # lime + tangerine
├── server.nix             # satsuma + bergamot only
├── satsuma/               # one file per service, grouped by function
│                          #   (system/ holds kernel, power, storage, upgrades)
├── bergamot/              # nixosConfigurations.bergamot (hostname mail)
├── pomelo/                # desktop (+ nfs.nix)
├── lime/                  # nix-darwin: Mac mini
├── tangerine/             # nix-darwin: laptop
├── pkgs/                  # local derivations (matrix-mcp, mindroom-nio, kiro-gateway)
├── dots/                  # dotfiles linked into the hosts (via homelab.nix)
├── docs/                  # per-topic runbooks (Obsidian vault)
├── scripts/               # deploy.sh, drvpaths.sh; not imported by the flake
└── tofu/                  # OpenTofu for OVHcloud, Cloudflare DNS and AWS SES
```

Shared config is plain NixOS/Darwin modules imported explicitly by each host;
there is no module framework.

## Secrets

Encrypted with [agenix](https://github.com/ryantm/agenix). Each host has a
`secrets/` directory of `.age` files next to its configuration:

```sh
cd satsuma   # or vps/, lime/
agenix -e secret.age -i /etc/ssh/ssh_host_ed25519_key
```

Recipients are declared in `<host>/secrets/secrets.nix`. See
[docs/Secrets.md](docs/Secrets.md) for the editing and rekeying workflow.

## Verifying a refactor

`scripts/drvpaths.sh` prints the `system.build.toplevel` store path of every
host. Identical output before and after a change means the build graph did not
move; a difference shows exactly which host changed.

```sh
scripts/drvpaths.sh > /tmp/after
diff scripts/drvpaths.baseline /tmp/after
```

## Docs

| Doc | Topic |
| --- | --- |
| [Setup Overview](docs/Setup%20Overview.md) | Hosts, hardware, services |
| [IP Address](docs/IP%20Address.md) | LAN address table |
| [Secrets](docs/Secrets.md) | agenix workflow |
| [Backup](docs/Backup.md) | satsuma snapshots, replication, offsite |
| [Monitoring](docs/Monitoring.md) | Prometheus, Grafana, alerting |
| [NFS](docs/NFS.md) | Exports and client mounts |
| [Media Stack](docs/Media%20Stack.md) | Arr stack, Immich, Jellyfin |
| [Stalwart](docs/Stalwart.md) | Mail server on `bergamot` |
| [DNS](docs/DNS.md) | Technitium on `orange` |
| [OpenCode](docs/OpenCode.md) | Centralised OpenCode + agents |
| [Vaultwarden CLI](docs/Vaultwarden%20CLI.md) | `rbw` setup and agent rules |
| [Hermes](docs/Hermes.md) | Hermes agent |
| [Tailscale](docs/Tailscale.md) | Tailnet dependencies and migration plan |
| [lime (macOS)](docs/lime%20(macOS).md) | Mac mini specifics |
| [iMessage Digest](docs/iMessage%20Digest.md) | Digest service on `lime` |
| [SMS Matrix Bridge](docs/SMS%20Matrix%20Bridge.md) | Pixel SMS bridge |
| [System Mail](docs/System%20Mail%20(Alerts).md) | Alert mail relay |
