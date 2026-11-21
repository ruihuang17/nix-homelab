{ config, pkgs, ... }:
{
  age.secrets.paperless_admin_pass.file = ../secrets/paperless_admin_pass.age;

  services.paperless = {
    enable = true;
    address = "127.0.0.1";
    port = 28981;
    passwordFile = config.age.secrets.paperless_admin_pass.path;
    dataDir = "/var/lib/paperless";
    domain = "paperless.local.estrogenuinely.ca";
    settings = {
      PAPERLESS_DBENGINE = "postgresql";
      PAPERLESS_DBHOST = "/run/postgresql";
      PAPERLESS_DBNAME = "paperless";
      PAPERLESS_DBUSER = "paperless";
      # no PAPERLESS_DBPASS — unix socket + peer auth handles it
      # 3.5+ restricts ALLOWED_HOSTS to PAPERLESS_URL's host when it is set;
      # also allow 127.0.0.1 so the blackbox probe on 127.0.0.1:28981 passes.
      PAPERLESS_ALLOWED_HOSTS = "paperless.local.estrogenuinely.ca,127.0.0.1";
    };
  };
}
