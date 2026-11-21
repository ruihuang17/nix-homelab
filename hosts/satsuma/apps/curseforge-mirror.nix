# Content-addressed mirror of the official CurseForge Linux AppImage.
# Upstream only exposes a permalink that always points at the newest build,
# so a nightly fetch is the only way to pin older versions.  Each download
# is stored under its own sha256 (never overwritten) and recorded in
# latest.json / history.jsonl so a Nix package can pin it by hash.
{ pkgs, lib, ... }:
let
  # The download URL is the stable "latest" link Overwolf publishes; it 302s
  # to the current version, so the script has to digest whatever arrives.
  upstreamUrl = "https://curseforge.overwolf.com/downloads/curseforge-latest-linux.AppImage";

  update = pkgs.writeShellApplication {
    name = "curseforge-mirror-update";
    runtimeInputs = with pkgs; [ curl coreutils jq openssl ];
    text = ''
      state="$STATE_DIRECTORY"
      url="${upstreamUrl}"
      mkdir -p "$state/blobs"

      # Clear debris from a run that was killed hard (SIGKILL skips the trap).
      rm -rf "$state"/tmp.*

      tmp=$(mktemp -d "$state/tmp.XXXXXX")
      trap 'rm -rf "$tmp"' EXIT

      curl --fail --location --silent --show-error --retry 3 \
        --output "$tmp/dl" "$url"

      # refuse to store an error page or a truncated download
      size=$(stat -c %s "$tmp/dl")
      magic=$(head -c4 "$tmp/dl" | tail -c3)   # bytes 2-4 of the ELF header
      if [ "$size" -lt 10000000 ] || [ "$magic" != ELF ]; then
        echo "download does not look like an AppImage (size=$size)" >&2
        exit 1
      fi

      hex=$(sha256sum "$tmp/dl" | cut -d' ' -f1)
      sri="sha256-$(openssl dgst -sha256 -binary "$tmp/dl" | base64 -w0)"

      old=$(jq -r '.sri // empty' "$state/latest.json" 2>/dev/null || true)
      if [ "$old" = "$sri" ]; then
        echo "unchanged ($sri)"
        exit 0
      fi

      # content-addressed: the file name is its own sha256, never overwritten
      mv -n "$tmp/dl" "$state/blobs/$hex.AppImage"
      chmod 0644 "$state/blobs/$hex.AppImage"

      jq -nc --arg sri "$sri" --arg hex "$hex" --arg size "$size" \
             --arg at "$(date -u +%FT%TZ)" \
        '{sri: $sri, hex: $hex, size: ($size | tonumber), fetchedAt: $at,
          file: "blobs/\($hex).AppImage"}' > "$tmp/latest.json"
      mv "$tmp/latest.json" "$state/latest.json"
      cat "$state/latest.json" >> "$state/history.jsonl"

      echo "new upstream build:"
      echo "  hash = \"$sri\";"
      echo "  file = $state/blobs/$hex.AppImage"
    '';
  };
in
{
  users.users.curseforge-mirror = {
    isSystemUser = true;
    group = "curseforge-mirror";
  };
  users.groups.curseforge-mirror = { };

  systemd.services.curseforge-mirror = {
    description = "Fetch the CurseForge AppImage and record its hash";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe update;
      User = "curseforge-mirror";
      StateDirectory = "curseforge-mirror";
      # 0755 keeps blobs/ readable by other local users (or by a web server
      # later) even though nothing currently serves them over HTTP.
      StateDirectoryMode = "0755";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  systemd.timers.curseforge-mirror = {
    description = "Daily check for a new CurseForge AppImage build";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "1h";
      Persistent = true;   # catch up if the host was off
    };
  };
}
