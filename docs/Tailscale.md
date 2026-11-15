# Tailscale

The tailnet is owned by `rui.huang17@protonmail.com` (tailnet
`tailf59fe4.ts.net`). That email changed, so Tailscale locks the account out of
the admin console ("Login name change detected"); devices keep working. The fix
Tailscale documents for a shared-domain account is a new tailnet, so the plan
is to move to a new tailnet owned by a Google account. Lena keeps her Gmail
account and is invited.

See [[Stalwart]], [[Backup]] and [[Monitoring]] for the services that cross the
tailnet, and [[NFS]] for the LAN subnet route.

## What depends on the tailnet

| Dependency | Where | Breaks if it changes |
| --- | --- | --- |
| satsuma `100.72.25.50` | `bergamot/satsuma-watcher.nix`, `bergamot/backup-target.nix` (`from=`), `bergamot/stalwart.nix` (LDAP) | satsuma-down alerts, offsite Postgres backup, mail logins |
| bergamot `100.91.236.114` | `homelab.nix`, `dots/ssh/config`, `satsuma/backup/postgres-backup.nix`, Prometheus scrape | ssh to the VPS, backups, monitoring |
| bergamot sshd only on `tailscale0` | `bergamot/configuration.nix` | access to the VPS during the move |
| satsuma subnet route `10.0.10.0/24` + exit node | admin console approval | remote LAN access |
| ACL policy, key expiry, MagicDNS | admin console | whatever they allow |

nginx (OpenCode, status page) and Postfix allow all of `100.64.0.0/10`, so new
addresses do not affect them.

Stalwart used to reach kanidm at `satsuma.tailf59fe4.ts.net`. The suffix is per
tailnet, so since 2026-11-15 it uses `ldaps://100.72.25.50:3636`; hostname
verification was already off.

## Temporary public ssh on bergamot

For the move, `bergamot/configuration.nix` accepts ssh on the public interface
from home's public IPv4 `173.35.163.247` only (`firewall.extraCommands`).
Reach it with:

```sh
ssh -o HostKeyAlias=100.91.236.114 root@15.235.101.89
```

`HostKeyAlias` reuses the key already known for the tailnet address. If the
home IP changes before the move, update the rule. **Remove the rule once
bergamot is on the new tailnet.**

## Plan

1. **Prepare** (done 2026-11-15): Stalwart LDAP by IP, temporary ssh rule.
   Still to do: save the ACL policy, DNS settings, and which devices have key
   expiry disabled from the old console.
2. **New tailnet:** sign up with the Google account, restore the ACL policy,
   enable MagicDNS, create a one-time pre-approved auth key for the servers.
3. **Test device:** join tangerine first.
4. **satsuma + bergamot, one window**, not 03:00–03:30 (backups). Expect
   watcher alert mail while they are apart. bergamot first, over the public
   ssh rule, then satsuma from the LAN (OpenCode runs on satsuma, so a session
   over Tailscale drops):
   ```sh
   sudo tailscale logout
   sudo tailscale up --auth-key=tskey-...
   ```
   Re-run `up` with the same flags the NixOS module uses; check with
   `tailscale debug prefs` that satsuma still advertises `10.0.10.0/24` and
   the exit node. In the new console: set each machine's IPv4 back to its old
   address, approve the route and exit node, disable key expiry for both.
5. **Verify:**
   - `tailscale ping` satsuma ↔ bergamot
   - `ssh root@bergamot`
   - `systemctl start restic-backups-postgres-vps` and read its log
   - a mail login, or from satsuma:
     `printf 'Subject: test\n\n' | sendmail -f alerts@estrogenuinely.ca rui@ruihuang.io`
   - Prometheus target `mail` up, watcher recovered
6. **Rest:** pomelo (keeps `--accept-routes=false`), iPhone, iPad; invite Lena,
   who moves celosia, hibiscus, minipc-1 and her iPhone. Delete the old
   tailnet.
7. **Clean up:** remove the temporary ssh rule from `bergamot/configuration.nix`.
   If an IP could not be restored, update `homelab.nix`,
   `bergamot/satsuma-watcher.nix`, `bergamot/backup-target.nix` and
   `bergamot/stalwart.nix` together and deploy satsuma and bergamot.
