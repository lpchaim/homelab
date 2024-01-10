{ config, lib, utils, ... }:

with lib;
let
  cfg = config.my.containers.services;
  inherit (utils) makeEnableOptionDefaultTrue makeDefault;
in
{
  options.my.containers.services = {
    traefik.enable = makeEnableOptionDefaultTrue "traefik";
    crowdsec.enable = makeEnableOptionDefaultTrue "crowdsec";
    cloudflare-ddns.enable = makeEnableOptionDefaultTrue "cloudflare-ddns";
  };

  config.my.containers.services.contents = mkIf cfg.enable {
    traefik = mkIf cfg.traefik.enable (makeDefault {
      image = "traefik:v2.10";
      environment = { CF_DNS_API_TOKEN = "\${secret_cloudflare_api_token}"; };
      networks = [ "default" "external" ];
      ports = [
        "${builtins.toString config.my.networking.ports.internal.http}:80"
        "${builtins.toString config.my.networking.ports.internal.https}:443"
        "8080:8080"
      ];
      volumes = [
        "${config.my.storage.getConfigPath "traefik"}:/etc/traefik"
        "${config.my.storage.getConfigPath "traefik"}/acme:/etc/traefik/acme"
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
      labels = {
        "com.centurylinklabs.watchtower.enable" = "false";
      };
    });

    crowdsec = mkIf cfg.crowdsec.enable (makeDefault {
      image = "crowdsecurity/crowdsec:latest";
      networks = [ "default" "external" ];
      volumes = [
        "${config.my.storage.getConfigPath "crowdsec"}:/etc/crowdsec"
        "${config.my.storage.getLogPath "crowdsec"}:/var/log/nginx"
        "${config.my.storage.getDataPath "crowdsec"}:/var/lib/crowdsec/data"
      ];
    });

    cloudflare-ddns = mkIf cfg.cloudflare-ddns.enable (makeDefault {
      image = "oznu/cloudflare-ddns:latest";
      environment = {
        API_KEY = "\${secret_cloudflare_api_token}";
        ZONE = config.my.domain;
        INTERFACE = "eth0";
        PROXIED = "true";
        RRTYPE = "AAAA";
      };
      network_mode = "host";
    });
  };
}
