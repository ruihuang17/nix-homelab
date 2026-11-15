# OVH infrastructure (OpenTofu)

Manages the OVH side of the homelab. Nix configures what runs on the hosts;
this directory creates the OVH resources they depend on.

| File | Purpose |
| --- | --- |
| `storage.tf` | Buckets `satsuma-backup` and `satsuma-tofu-state`, each with its own S3 user, credential and bucket-scoped policy |
| `vps.tf` | Reads the existing mail VPS (data source only) |
| `outputs.tf` | Sensitive `KEY=value` blocks in the format `restic_s3_env.age` uses |
| `encryption.tf` | Client-side AES-GCM encryption of state and plans (PBKDF2 passphrase) |
| `backend.tf.example` | S3 remote state on OVH with native locking |

`ovh_vps` places a paid order on create and is slated for a rework upstream,
so the VPS is read-only here. `satsuma-backup` already exists and is imported
by the `import` block in `storage.tf`. It has `prevent_destroy` set.

## Credentials

Create a token at https://auth.ca.ovhcloud.com/api/createToken with these
rights. Rule paths do not include the API version: `/publicCloud/...` covers
the `/v2/publicCloud/...` routes the bucket resource uses, and a rule written
as `/v2/...` grants nothing.

| Method | Path |
| --- | --- |
| GET, POST, PUT, DELETE | `/cloud/project/<project_id>/*` |
| GET, POST, PUT, DELETE | `/publicCloud/project/<project_id>/*` |
| GET | `/vps/<vps>` and `/vps/<vps>/*` |

Keep the keys in an agenix secret and load them into the shell:

```bash
cd /etc/nixos/satsuma/secrets
agenix -e tofu_ovh_env.age -i /etc/ssh/ssh_host_ed25519_key
set -a; source <(agenix -d tofu_ovh_env.age -i ~/.ssh/id_ed25519); set +a
```

The file holds `OVH_ENDPOINT=ovh-ca`, `OVH_APPLICATION_KEY`,
`OVH_APPLICATION_SECRET`, `OVH_CONSUMER_KEY`, `TF_VAR_state_passphrase`, and
the state user's `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` for the backend.
A copy lives in Vaultwarden as "Tofu OVHcloud API Key".

The control panel's API keys page lists applications, not consumer keys, and
deleting an application revokes every key under it. Keep one consumer key per
application. To rotate: create a new token, replace the `OVH_*` values here
and in Vaultwarden, run `tofu plan`, then delete the old application.

## State encryption

`encryption.tf` encrypts state and plan files with a key derived from
`TF_VAR_state_passphrase` (at least 16 characters, e.g. `openssl rand -hex 32`).
`enforced = true` makes tofu refuse to write unencrypted state.

Without the passphrase the state is unrecoverable, and the S3 credentials in it
cannot be re-imported. Keep a copy in Vaultwarden as well as agenix.

Rotating the passphrase: add a second `pbkdf2` key provider and `aes_gcm`
method with the new passphrase, point `state`/`plan` at them with the old
method in a `fallback` block, run `tofu apply`, then remove the old ones.

## Usage

State lives in `s3://satsuma-tofu-state/homelab.tfstate`, encrypted, with an
S3 lockfile. On a fresh checkout:

```bash
cd /etc/nixos/tofu
cp terraform.tfvars.example terraform.tfvars   # fill in project_id and VPS name
cp backend.tf.example backend.tf
nix shell nixpkgs#opentofu
tofu init
tofu plan
```

The bucket and its user are created by this config, so bootstrapping from
scratch means a first apply with local state, then
`tofu output -raw s3_env_state` into the env file and `tofu init -migrate-state`.

Credentials created here can feed back into agenix, for example
`tofu output -raw s3_env_backup | agenix -e restic_s3_env.age`.
The first apply creates new S3 users, so the existing restic keys keep
working until `restic_s3_env.age` is replaced.
