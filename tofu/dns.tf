locals {
  cloudflare_zones = {
    "estrogenuinely.ca" = "a6b5e07832e79703ec440d6e9fb04c7b"
    "ruihuang.io"       = "781625ec151b95aac0b376524d2e0e33"
  }

  # Home WAN records. satsuma's cloudflare-ddns service keeps their content
  # current (hosts/satsuma/core/ddns.nix); tofu owns everything else about them.
  # The addresses here are only used when tofu creates a record from scratch.
  dynamic_records = {
    "estrogenuinely.ca/@/A"    = "173.35.163.247"
    "estrogenuinely.ca/@/AAAA" = "2607:fea8:fca0:817a:3a05:25ff:fe30:c7a1"
    "ruihuang.io/@/A"          = "173.35.163.247"
  }

  mail_ipv4 = "15.235.101.89"
  mail_ipv6 = "2607:5300:205:200::d27c"

  # Keys are "<zone>/<name>/<type>[/<n>]"; "@" is the zone apex. All records
  # are DNS-only (grey cloud). TTL 1 means "automatic". TXT content keeps the
  # surrounding quotes because that is how Cloudflare stores it.
  dns_records = {
    # estrogenuinely.ca: services on satsuma (home)
    "estrogenuinely.ca/collabora/CNAME"           = { content = "estrogenuinely.ca" }
    "estrogenuinely.ca/home/CNAME"                = { content = "estrogenuinely.ca" }
    "estrogenuinely.ca/idm/CNAME"                 = { content = "estrogenuinely.ca" }
    "estrogenuinely.ca/matrix/CNAME"              = { content = "estrogenuinely.ca" }
    "estrogenuinely.ca/nextcloud/CNAME"           = { content = "estrogenuinely.ca" }
    "estrogenuinely.ca/vaultwarden/CNAME"         = { content = "estrogenuinely.ca" }
    "estrogenuinely.ca/pancakeslicer.local/CNAME" = { content = "estrogenuinely.ca" }

    # estrogenuinely.ca: mail (Stalwart on bergamot, outbound via SES).
    # See docs/Stalwart.md.
    "estrogenuinely.ca/mail/A"                                            = { content = local.mail_ipv4 }
    "estrogenuinely.ca/mail/AAAA"                                         = { content = local.mail_ipv6 }
    "estrogenuinely.ca/@/MX"                                              = { content = "mail.estrogenuinely.ca", priority = 10 }
    "estrogenuinely.ca/@/TXT"                                             = { content = "\"v=spf1 include:amazonses.com mx -all\"", ttl = 3600 }
    "estrogenuinely.ca/_dmarc/TXT"                                        = { content = "\"v=DMARC1; p=none;\"", ttl = 3600 }
    "estrogenuinely.ca/autoconfig/CNAME"                                  = { content = "mail.estrogenuinely.ca" }
    "estrogenuinely.ca/autodiscover/CNAME"                                = { content = "mail.estrogenuinely.ca" }
    "estrogenuinely.ca/bounce/MX"                                         = { content = "feedback-smtp.us-east-2.amazonses.com", priority = 10, ttl = 3600 }
    "estrogenuinely.ca/bounce/TXT"                                        = { content = "\"v=spf1 include:amazonses.com ~all\"", ttl = 3600 }
    "estrogenuinely.ca/abqh6onfi7nmp5gxtzyj2dmmvw4jrhpj._domainkey/CNAME" = { content = "abqh6onfi7nmp5gxtzyj2dmmvw4jrhpj.dkim.amazonses.com", ttl = 3600 }
    "estrogenuinely.ca/ermcwus37spazeipgwxwham3mjm4kz3g._domainkey/CNAME" = { content = "ermcwus37spazeipgwxwham3mjm4kz3g.dkim.amazonses.com", ttl = 3600 }
    "estrogenuinely.ca/oq6gqz5o676jhncessicl2jo6zlbpjg2._domainkey/CNAME" = { content = "oq6gqz5o676jhncessicl2jo6zlbpjg2.dkim.amazonses.com", ttl = 3600 }
    "estrogenuinely.ca/_caldavs._tcp/SRV"                                 = { srv = { port = 443 } }
    "estrogenuinely.ca/_carddavs._tcp/SRV"                                = { srv = { port = 443 } }
    "estrogenuinely.ca/_imaps._tcp/SRV"                                   = { srv = { port = 993 } }
    "estrogenuinely.ca/_imap._tcp/SRV"                                    = { srv = { port = 143 } }
    "estrogenuinely.ca/_jmap._tcp/SRV"                                    = { srv = { port = 443 } }
    "estrogenuinely.ca/_submissions._tcp/SRV"                             = { srv = { port = 465 } }
    "estrogenuinely.ca/_submission._tcp/SRV"                              = { srv = { port = 587 } }

    # ruihuang.io: website on satsuma, mail on Proton
    "ruihuang.io/www/CNAME"                    = { content = "ruihuang.io" }
    "ruihuang.io/@/MX/1"                       = { content = "mail.protonmail.ch", priority = 10 }
    "ruihuang.io/@/MX/2"                       = { content = "mailsec.protonmail.ch", priority = 20 }
    "ruihuang.io/@/TXT/spf"                    = { content = "\"v=spf1 include:_spf.protonmail.ch ~all\"" }
    "ruihuang.io/@/TXT/proton-verification"    = { content = "\"protonmail-verification=4885e11cb801671d0f57c45dda994100ea467ac0\"" }
    "ruihuang.io/_dmarc/TXT"                   = { content = "\"v=DMARC1; p=quarantine\"" }
    "ruihuang.io/protonmail._domainkey/CNAME"  = { content = "protonmail.domainkey.d4bj3nikkby4v63tkduilvg2zkmbwhlg7qxzejx6xba4ym7drmuvq.domains.proton.ch" }
    "ruihuang.io/protonmail2._domainkey/CNAME" = { content = "protonmail2.domainkey.d4bj3nikkby4v63tkduilvg2zkmbwhlg7qxzejx6xba4ym7drmuvq.domains.proton.ch" }
    "ruihuang.io/protonmail3._domainkey/CNAME" = { content = "protonmail3.domainkey.d4bj3nikkby4v63tkduilvg2zkmbwhlg7qxzejx6xba4ym7drmuvq.domains.proton.ch" }
  }

  dns_records_parsed = {
    for key, r in merge(local.dns_records, { for k, ip in local.dynamic_records : k => { content = ip } }) : key => merge(r, {
      zone = split("/", key)[0]
      name = split("/", key)[1] == "@" ? split("/", key)[0] : "${split("/", key)[1]}.${split("/", key)[0]}"
      type = split("/", key)[2]
    })
  }
}

resource "cloudflare_dns_record" "this" {
  for_each = { for k, r in local.dns_records_parsed : k => r if !contains(keys(local.dynamic_records), k) }

  zone_id  = local.cloudflare_zones[each.value.zone]
  name     = each.value.name
  type     = each.value.type
  content  = lookup(each.value, "srv", null) == null ? each.value.content : null
  priority = lookup(each.value, "srv", null) == null ? lookup(each.value, "priority", null) : 0
  ttl      = lookup(each.value, "ttl", 1)
  proxied  = false

  data = lookup(each.value, "srv", null) == null ? null : {
    priority = 0
    weight   = 1
    port     = each.value.srv.port
    target   = "mail.estrogenuinely.ca"
  }
}

resource "cloudflare_dns_record" "dynamic" {
  for_each = local.dynamic_records

  zone_id = local.cloudflare_zones[local.dns_records_parsed[each.key].zone]
  name    = local.dns_records_parsed[each.key].name
  type    = local.dns_records_parsed[each.key].type
  content = each.value
  ttl     = 1
  proxied = false

  lifecycle {
    ignore_changes = [content]
  }
}
