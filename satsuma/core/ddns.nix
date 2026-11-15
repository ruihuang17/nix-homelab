{ config, ... }:
{
  # Keeps the home WAN records in Cloudflare pointed at satsuma's public
  # address. Tofu owns the records themselves (tofu/dns.tf, "dynamic") and
  # ignores their content, so IP changes here do not show up as drift.
  # The ruihuang.io apex has no AAAA record, so it is IPv4 only.
  age.secrets.cloudflare_ddns_env = {
    file = ../secrets/cloudflare_ddns_env.age;
    owner = config.services.cloudflare-ddns.user;
  };

  services.cloudflare-ddns = {
    enable = true;
    credentialsFile = config.age.secrets.cloudflare_ddns_env.path;
    ip4Domains = [
      "estrogenuinely.ca"
      "ruihuang.io"
    ];
    ip6Domains = [ "estrogenuinely.ca" ];
    proxied = "false";
    ttl = 1;
  };
}
