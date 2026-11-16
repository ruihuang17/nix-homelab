# CI deploy

`.github/workflows/deploy.yml` deploys satsuma and bergamot on every push to
`main` (except docs/tofu/README-only changes), or on demand from the Actions tab.

Flow: the runner joins the tailnet as `tag:ci`, SSHes to satsuma
(`100.72.25.50`) with a key that is forced to run one command
(`satsuma/system/ci-deploy.nix`): `git pull --ff-only` in `/etc/nixos`, then
`scripts/deploy.sh satsuma bergamot`. satsuma builds; the runner does no Nix work.

lime, tangerine and pomelo are not deployed by CI. Run `scripts/deploy.sh pomelo`
from satsuma once it is on, and `darwin-rebuild` on the Macs.

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
4. The first deploy of `ci-deploy.nix` itself must be done by hand
   (`scripts/deploy.sh satsuma` from satsuma), since CI cannot use a key that
   is not installed yet.

## Rotating the key

`ssh-keygen -t ed25519 -f ci_deploy -C github-actions-deploy`, replace the public
key in `ci-deploy.nix`, update `DEPLOY_SSH_KEY`, and deploy by hand.

## Notes

- `git pull --ff-only` fails if satsuma holds an unpushed commit (the 04:00
  auto-upgrade lock bump is pushed right after it runs). Push from satsuma and re-run.
- Do not add a `pull_request` trigger; the job holds production credentials.
