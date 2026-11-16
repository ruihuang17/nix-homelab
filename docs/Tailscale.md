# Tailscale

The tailnet is owned by the Google account `rui.huang17@hotmail.com`
(MagicDNS suffix `tail8a5bcd.ts.net`). It replaced the old tailnet owned by
`rui.huang17@protonmail.com` (`tailf59fe4.ts.net`) on 2026-11-15, after that
account's email changed and Tailscale locked it out of the admin console
("Login name change detected"). Tailscale cannot move a shared-domain account
to a new email, so the fix was a new tailnet. Lena keeps her Gmail account and
is invited.

See [[Stalwart]], [[Backup]] and [[Monitoring]] for the services that cross the
tailnet, and [[NFS]] for the LAN subnet route.

## Addresses

The servers were given their old IPv4 addresses in the new admin console, so
no configuration changed.

| Machine | Tailscale IPv4 | Notes |
| --- | --- | --- |
| satsuma | `100.72.25.50` | subnet route `10.0.10.0/24`, exit node, key expiry off |
| bergamot (hostname `mail`) | `100.91.236.114` | key expiry off |
| tangerine | `100.86.214.60` | |

## What depends on the tailnet

| Dependency | Where | Breaks if it changes |
| --- | --- | --- |
| satsuma `100.72.25.50` | `hosts/bergamot/satsuma-watcher.nix`, `hosts/bergamot/backup-target.nix` (`from=`), `hosts/bergamot/stalwart.nix` (LDAP) | satsuma-down alerts, offsite Postgres backup, mail logins |
| bergamot `100.91.236.114` | `homelab.nix`, `dots/ssh/config`, `hosts/satsuma/backup/postgres-backup.nix`, Prometheus scrape | ssh to the VPS, backups, monitoring |
| bergamot sshd only on `tailscale0` | `hosts/bergamot/configuration.nix` | all ssh access to the VPS |
| satsuma subnet route + exit node | admin console approval | remote LAN access |
| ACL policy, key expiry, MagicDNS | admin console | whatever they allow |

nginx (OpenCode, status page) and Postfix allow all of `100.64.0.0/10`, so new
addresses do not affect them.

Nothing uses a MagicDNS name. Stalwart reaches kanidm at
`ldaps://100.72.25.50:3636`; hostname verification is off because kanidm's
certificate is for `idm.estrogenuinely.ca`. Keep it that way: the `ts.net`
suffix changes with the tailnet, the IP can be set back.

## Moving a server to another tailnet

Done this way on 2026-11-15; reuse it if the tailnet changes again.

1. Save the ACL policy, DNS settings and the key-expiry list from the old
   console. Create a one-time, pre-approved auth key in the new one.
2. bergamot's sshd only listens on `tailscale0`, so add a temporary rule to
   `hosts/bergamot/configuration.nix` for home's public IPv4 before you start:
   ```nix
   networking.firewall.extraCommands = ''
     iptables -A nixos-fw -p tcp -s <home-ip>/32 --dport 22 -j nixos-fw-accept
   '';
   networking.firewall.extraStopCommands = ''
     iptables -D nixos-fw -p tcp -s <home-ip>/32 --dport 22 -j nixos-fw-accept 2>/dev/null || true
   '';
   ```
   Reach it with `ssh -o HostKeyAlias=100.91.236.114 root@15.235.101.89`.
3. Move satsuma and bergamot in one window, not 03:00–03:30 (backups). The
   watcher sends alert mail while they are apart. Do satsuma from the LAN:
   OpenCode runs there, so a session over Tailscale drops.
   ```sh
   sudo tailscale logout
   sudo tailscale up --auth-key=tskey-...
   ```
   Check `tailscale debug prefs`: satsuma must still advertise `10.0.10.0/24`,
   `0.0.0.0/0` and `::/0`.
4. In the new console: set each server's IPv4 back to its old address, approve
   the route and exit node, disable key expiry.
5. Verify:
   - `tailscale ping` satsuma ↔ bergamot
   - `ssh root@bergamot`
   - `systemctl start restic-backups-postgres-vps` and read its log
   - from satsuma:
     `printf 'Subject: test\n\n' | sendmail -f alerts@estrogenuinely.ca rui@ruihuang.io`
     (the sender must be on Stalwart's allowed list; `root@` is rejected)
   - Prometheus target `node bergamot` up, `/var/lib/satsuma-watcher/fail_count` is 0
6. Remove the temporary ssh rule and deploy bergamot.

If an address cannot be restored, update `homelab.nix`,
`hosts/bergamot/satsuma-watcher.nix`, `hosts/bergamot/backup-target.nix` and
`hosts/bergamot/stalwart.nix` together and deploy satsuma and bergamot.

## Status of the 2026-11-15 move

- [x] satsuma, bergamot, tangerine on the new tailnet; checks in step 5 passed
- [x] temporary ssh rule removed
- [ ] pomelo (keeps `--accept-routes=false`, see [[NFS]]), iPhone, iPad
- [ ] invite Lena; she moves celosia, hibiscus, minipc-1 and her iPhone
- [ ] remove the two unnamed offline machines from the new console
- [ ] delete the old tailnet
