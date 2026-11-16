# CI deploy

`.github/workflows/deploy.yml` is a manually triggered workflow (Actions tab →
deploy → Run workflow). Tick the hosts to deploy: satsuma and bergamot are on by
default, pomelo and lime are opt-in. Nothing deploys on push.

Flow: the runner joins the tailnet as `tag:ci` and SSHes to satsuma
(`100.72.25.50`) with a key that is forced to run one script
(`satsuma/system/ci-deploy.nix`). The script reads the host list the runner
sends, rejects anything outside `satsuma bergamot pomelo lime`, runs
`git pull --ff-only` in `/etc/nixos`, then `scripts/deploy.sh -k` for the NixOS
hosts. For lime it SSHes from satsuma to the Mac, pulls `~/nix-homelab` and runs
`sudo -n darwin-rebuild switch --flake .#lime`. satsuma builds the NixOS hosts;
the runner does no Nix work. The job fails if any selected host fails.

Not covered: tangerine (its sudo needs a password, and a laptop is often asleep).
Run `sudo darwin-rebuild switch --flake ~/nix-homelab#tangerine` on it. pomelo is
skipped by the desktop being off; the job will report it failed.

## Setup (one time)

1. Tailscale admin console, Access controls: define `tag:ci` in `tagOwners`
   and allow `tag:ci` to reach satsuma on `tcp:22`.
2. Settings, OAuth clients: create a client with the `auth_keys` write scope
   and tag `tag:ci`.
3. GitHub repo secrets:
   - `TS_OAUTH_CLIENT_ID`, `TS_OAUTH_SECRET`: from step 2.
   - `DEPLOY_SSH_KEY`: the private key matching the public key in
     `satsuma/system/ci-deploy.nix`.
   - `SATSUMA_HOST_KEY`: `100.72.25.50 ssh-ed25519 AAAA...` (output of
     `ssh-keyscan -t ed25519 100.72.25.50`).
4. Changes to `ci-deploy.nix` itself take effect only after a manual
   `scripts/deploy.sh satsuma` on satsuma, since CI runs the installed script.

## Rotating the key

`ssh-keygen -t ed25519 -f ci_deploy -C github-actions-deploy`, replace the public
key in `ci-deploy.nix`, update `DEPLOY_SSH_KEY`, and deploy by hand.

## Notes

- `git pull --ff-only` fails if satsuma holds an unpushed commit (the 04:00
  auto-upgrade lock bump is pushed right after it runs). Push from satsuma and re-run.
- Do not add a `pull_request` trigger; the job holds production credentials.
