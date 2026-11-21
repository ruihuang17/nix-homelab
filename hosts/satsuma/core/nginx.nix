{
  pkgs,
  config,
  lib,
  ...
}:
let
  homelab = import ../../../homelab.nix;
in
{
  # Mitigation for CVE-2026-123007 / CVE-2026-123633 (nginx HTTP/2 RCE,
  # fixed in 1.30.7). Forces HTTP/2 off on every vhost, including those
  # defined in other modules. Remove once nixos-unstable ships nginx >= 1.30.7.
  options.services.nginx.virtualHosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        config.http2 = lib.mkForce false;
      }
    );
  };

  config = {
    age.secrets.cloudflare_api.file = ../secrets/cloudflare_api.age;

    security.acme = {
      acceptTerms = true;
      defaults.email = "rui.huang17@protonmail.com";
      certs."ruihuang.io" = {
        domain = "ruihuang.io";
        extraDomainNames = [
          "*.ruihuang.io"
          "*.local.ruihuang.io"
        ];
        group = config.services.nginx.group;
        dnsProvider = "cloudflare";
        environmentFile = config.age.secrets.cloudflare_api.path;
        dnsResolver = "1.1.1.1:53";
        extraLegoRunFlags = [ "--ari-disable" ];
      };
      certs."estrogenuinely.ca" = {
        domain = "estrogenuinely.ca";
        extraDomainNames = [
          "*.estrogenuinely.ca"
          "*.local.estrogenuinely.ca"
        ];
        group = config.services.nginx.group;
        dnsProvider = "cloudflare";
        # Same Cloudflare API token manages both the ruihuang.io and
        # estrogenuinely.ca zones, so the existing credentials file is reused.
        environmentFile = config.age.secrets.cloudflare_api.path;
        dnsResolver = "1.1.1.1:53";
        extraLegoRunFlags = [ "--ari-disable" ];
      };
    };

    services.nginx = {
      enable = true;
      # I recommend these, but it's up to you
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;

      virtualHosts = {
        "ruihuang.io" = {
          useACMEHost = "ruihuang.io";
          forceSSL = true;
          root = "/var/lib/www/main/public";
          locations."/countdown/" = {
            alias = "/var/lib/www/countdown/";
            index = "index.html";
          };
        };

        "www.ruihuang.io" = {
          useACMEHost = "ruihuang.io";
          forceSSL = true;
          globalRedirect = "ruihuang.io";
        };

        # Apex vhost: static page plus Matrix delegation, since server_name is
        # estrogenuinely.ca but Synapse lives at matrix.estrogenuinely.ca.
        "estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          root = "/var/lib/www/estrogenuinely";
          locations."= /.well-known/matrix/server" = {
            extraConfig = ''
              default_type application/json;
              return 200 '{"m.server": "matrix.estrogenuinely.ca:443"}';
            '';
          };
          locations."= /.well-known/matrix/client" = {
            extraConfig = ''
              default_type application/json;
              add_header Access-Control-Allow-Origin "*";
              return 200 '{"m.homeserver": {"base_url": "https://matrix.estrogenuinely.ca"}}';
            '';
          };
        };

        "nextcloud.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
        };

        "collabora.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://[::1]:${toString config.services.collabora-online.port}";
            proxyWebsockets = true; # collabora uses websockets
          };
        };

        "home.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://${homelab.ip "homeassistant"}:8123";
            proxyWebsockets = true;
          };
        };

        "idm.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "https://127.0.0.1:8443";
            extraConfig = ''
              proxy_ssl_server_name on;
            '';
          };
        };

        "pancakeslicer.local.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          extraConfig = ''
            # Model uploads (server caps them at 512 MiB by default).
            client_max_body_size 1g;
            client_body_buffer_size 1024k;
          '';
          locations."/" = {
            proxyPass = "http://127.0.0.1:6868";
            proxyWebsockets = true;
            extraConfig = ''
              # Slicing progress streams over SSE; don't buffer it.
              proxy_buffering off;
              proxy_read_timeout 600s;
              proxy_send_timeout 600s;
            '';
          };
        };

        "paperless.local.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:28981";
          };
        };

        "immich.local.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          extraConfig = ''
            client_max_body_size 50000M;
            client_body_buffer_size 1024k;
          '';
          locations."/" = {
            proxyPass = "http://[::1]:2283";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_request_buffering off;
              proxy_redirect off;
              proxy_read_timeout 600s;
              proxy_send_timeout 600s;
              send_timeout 600s;
            '';
          };
        };

        "jellyfin.local.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://${homelab.ip "lime"}:8096";
          };
        };

        "sonarr.local.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8989";
          };
        };

        "radarr.local.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:7878";
          };
        };

        "prowlarr.local.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:9696";
          };
        };

        "vaultwarden.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
        };

        "dns.local.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://${homelab.ip "orange"}:5380";
          };
        };

        # LAN-only Synapse endpoint for the air-gapped SMS bridge phone.
        # Resolves to 10.0.10.72 via internal DNS (*.local.* wildcard cert),
        # so the phone never hairpins out to the public WAN IP.
        "matrix.local.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8008";
            proxyWebsockets = true;
          };
        };

        "matrix.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8008";
          };
        };

        # Public mirror of the CurseForge AppImage that curseforge-mirror.service
        # fetches nightly (content-addressed blobs). Blobs are anonymous too:
        # it is the same installer Overwolf serves to anyone, so nothing here
        # is worth gating. The rate limit still protects the home uplink.
        "mirror.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          # Only the JSON records are anonymous: they contain hashes and
          # timestamps, no copyrighted content, and let monitoring check
          # freshness without holding the credential.
          locations."= /latest.json" = {
            alias = "/var/lib/curseforge-mirror/latest.json";
            extraConfig = ''
              add_header Cache-Control "no-cache";
            '';
          };
          locations."= /history.jsonl" = {
            alias = "/var/lib/curseforge-mirror/history.jsonl";
            extraConfig = ''
              add_header Cache-Control "no-cache";
            '';
          };
          locations."/blobs/" = {
            alias = "/var/lib/curseforge-mirror/blobs/";
            extraConfig = ''
              # The blob is ~150 MB over a home uplink; keep one abusive
              # client from starving everything else. Full-speed for the
              # first 100 MB (nix fetches are small), then capped.
              limit_rate_after 100m;
              limit_rate 20m;
            '';
          };
          locations."/" = {
            return = "404";
          };
        };

        "mautrix-wsproxy.local.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:29331";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_read_timeout 3600s;
              proxy_send_timeout 3600s;
            '';
          };
        };

        "grafana.local.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3000";
            proxyWebsockets = true; # Grafana live uses websockets
          };
        };

        "hermes.local.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:9119";
            proxyWebsockets = true; # dashboard /api/ws and /api/pty
          };
        };

        "prometheus.local.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:9090";
          };
        };

        # Grove is a static dashboard with a small read-only Prometheus proxy.
        # Keep the vhost on the LAN/tailnet; it is not a public status page.
        "grove.local.estrogenuinely.ca" = {
          useACMEHost = "estrogenuinely.ca";
          forceSSL = true;
          root = "/var/lib/www/grove";
          extraConfig = ''
            allow 10.0.0.0/8;
            allow 100.64.0.0/10;
            allow 127.0.0.1;
            allow ::1;
            allow fd7a:115c:a1e0::/48;
            deny all;
          '';
          locations."/api/prom/" = {
            proxyPass = "http://127.0.0.1:9090/";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_read_timeout 60s;
              proxy_send_timeout 60s;
              limit_except GET {
                deny all;
              }
            '';
          };
          locations."/assets/" = {
            extraConfig = ''
              expires 1y;
            '';
          };
          locations."/" = {
            extraConfig = ''
              try_files $uri $uri/ /index.html;
              expires -1;
            '';
          };
        };

      };
    };
  };
}
