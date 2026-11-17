#!/usr/bin/env bash
# Deploy this flake to one or more hosts.
#
#   scripts/deploy.sh                       # all five hosts, in parallel
#   scripts/deploy.sh satsuma               # just one
#   scripts/deploy.sh bergamot lime         # several
#   scripts/deploy.sh -b all                # build only, no switch
#   scripts/deploy.sh -B satsuma bergamot   # build bergamot on satsuma, push it
#
# This checkout (including uncommitted edits to tracked files) is copied into
# each host's Nix store, and every host evaluates, builds and switches itself,
# so the nix-darwin Macs deploy the same way as the NixOS hosts. Hosts are
# reached through the ssh aliases in dots/ssh/config (installed on every host),
# so there are no addresses to keep in sync here.
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
all_hosts=(satsuma bergamot pomelo lime tangerine)

usage() {
  cat <<'EOF'
Usage: scripts/deploy.sh [options] [host...]

Hosts: satsuma, bergamot, pomelo, lime, tangerine, all (default: all)

Options:
  -b, --build          build instead of switching
  -B, --build-on HOST  build the NixOS hosts on HOST and push the result,
                       instead of building on each target (darwin hosts
                       always build on themselves)
  -s, --serial         one host at a time, with Nix's live progress display
  -k, --keep-going     with --serial, continue after a host fails
  -n, --dry-run        print the commands without running them
  -h, --help           show this help

By default hosts deploy in parallel; each line of output is prefixed with the
host name and the full log of each host is kept in a temporary directory.
EOF
}

action=switch
build_on=
serial=0
dry_run=0
keep_going=0
targets=()

is_host() {
  local h
  for h in "${all_hosts[@]}"; do [[ $1 == "$h" ]] && return 0; done
  return 1
}

while (($#)); do
  case "$1" in
    -b | --build) action=build ;;
    -B | --build-on)
      build_on=${2:-}
      shift
      ;;
    --build-on=*) build_on=${1#*=} ;;
    -s | --serial) serial=1 ;;
    -k | --keep-going) keep_going=1 ;;
    -n | --dry-run) dry_run=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    all) targets+=("${all_hosts[@]}") ;;
    *)
      if is_host "$1"; then
        targets+=("$1")
      else
        echo "deploy: unknown host or option: $1" >&2
        usage >&2
        exit 2
      fi
      ;;
  esac
  shift
done

((${#targets[@]})) || targets=("${all_hosts[@]}")

# Dedupe while preserving order (`all satsuma` should deploy satsuma once).
mapfile -t targets < <(printf '%s\n' "${targets[@]}" | awk '!seen[$0]++')

is_darwin() { [[ $1 == lime || $1 == tangerine ]]; }

if [[ -n $build_on ]] && { ! is_host "$build_on" || is_darwin "$build_on"; }; then
  echo "deploy: --build-on needs a NixOS host, got: ${build_on:-nothing}" >&2
  exit 2
fi

# The flake name is not always the hostname: `bergamot` runs as hostname `mail`
# (the provider's reverse DNS fixes it). Used only to detect the local machine.
hostname_of() {
  case "$1" in
    bergamot) echo mail ;;
    *) echo "$1" ;;
  esac
}

this_host=$(hostname -s)
is_local() { [[ $this_host == "$(hostname_of "$1")" ]]; }

# The login user for a host, from the ssh config (root on the servers, rhuang
# on pomelo and the Macs). The local machine is whoever runs the script.
user_of() {
  if is_local "$1"; then
    id -un
  else
    ssh -G "$1" 2>/dev/null | awk '$1 == "user" { print $2; exit }'
  fi
}

ssh_opts=(-o BatchMode=yes -o ConnectTimeout=10)
export NIX_SSHOPTS="${ssh_opts[*]}"

run() {
  printf '==>'
  printf ' %q' "$@"
  printf '\n'
  ((dry_run)) || "$@"
}

# Runs a command on a host: directly if it is this machine, otherwise over ssh.
# --serial gets a tty so Nix draws its progress display.
on_host() {
  local host=$1
  shift
  if is_local "$host"; then
    run "$@"
  else
    local tty=()
    ((serial)) && tty=(-t)
    run ssh "${ssh_opts[@]}" "${tty[@]}" "$host" "$(printf '%q ' "$@")"
  fi
}

# Without a tty Nix prints nothing while building; -L streams the build logs.
log_flags=()
((serial)) || log_flags=(-L)

deploy_one() {
  local host=$1 builder=$1
  if [[ -n $build_on ]] && ! is_darwin "$host"; then
    builder=$build_on
  fi

  # Only this checkout is pushed. The builder fetches the locked inputs itself
  # (GitHub tarballs checked against flake.lock), which is faster for bergamot
  # than uploading nixpkgs from home.
  if ! is_local "$builder"; then
    run nix copy --to "ssh-ng://$builder" "$src" || return 1
  fi

  local cmd
  if [[ $action == build ]]; then
    local attr=nixosConfigurations.$host.config.system.build.toplevel
    is_darwin "$host" && attr=darwinConfigurations.$host.system
    cmd=(nix build --no-link --print-out-paths "${log_flags[@]}" "$src#$attr")
  elif is_darwin "$host"; then
    # Full path: tangerine's sudoers rule allows exactly this command.
    cmd=(sudo -n /run/current-system/sw/bin/darwin-rebuild switch --flake "$src#$host" "${log_flags[@]}")
  else
    cmd=(nixos-rebuild switch --flake "$src#$host" "${log_flags[@]}")
    local user
    if [[ $builder != "$host" ]]; then
      user=$(user_of "$host")
      cmd+=(--target-host "$user@$host")
    else
      user=$(user_of "$builder")
    fi
    [[ $user != root ]] && cmd+=(--elevate=sudo)
  fi

  on_host "$builder" "${cmd[@]}"
}

# The flake as Nix sees it: a store path holding this checkout's tracked files.
# `nix flake metadata` would only compute the path; archive puts it in the
# local store so it can be copied.
src=$(nix flake archive --json "$repo_root" | jq -r .path)

ok=()
failed=()

if ((serial || dry_run)); then
  for host in "${targets[@]}"; do
    ((${#targets[@]} > 1)) && echo "### $host"
    if deploy_one "$host"; then
      ok+=("$host")
    else
      failed+=("$host")
      ((keep_going || dry_run)) || break
    fi
  done
else
  logdir=$(mktemp -d "${TMPDIR:-/tmp}/deploy.XXXXXX")
  width=0
  for host in "${targets[@]}"; do ((${#host} > width)) && width=${#host}; done

  # Ctrl-C stops every host's job, not just the script.
  trap 'trap - INT TERM; kill 0' INT TERM

  declare -A pids
  for host in "${targets[@]}"; do
    prefix=$(printf '%-*s | ' "$width" "$host")
    (deploy_one "$host" </dev/null 2>&1 | tee "$logdir/$host.log" |
      awk -v p="$prefix" '{ print p $0; fflush() }') &
    pids[$host]=$!
  done

  for host in "${targets[@]}"; do
    if wait "${pids[$host]}"; then
      ok+=("$host")
    else
      failed+=("$host")
    fi
  done
  echo "logs: $logdir"
fi

((dry_run)) && exit 0

verb=deployed
[[ $action == build ]] && verb=built
((${#ok[@]})) && echo "$verb: ${ok[*]}"
if ((${#failed[@]})); then
  echo "failed: ${failed[*]}" >&2
  exit 1
fi
