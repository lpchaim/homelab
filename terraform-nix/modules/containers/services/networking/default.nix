{ config, lib, utils, ... }@args:

with lib;
let
  cfg = config.my.containers.services;
  inherit (utils) makeEnableOptionDefaultTrue makeDefault;
in
{
  imports = [
    (import ./traefik args)
  ];

  options.my.containers.services = {
    cloudflare-ddns.enable = makeEnableOptionDefaultTrue "cloudflare-ddns";
    crowdsec.enable = makeEnableOptionDefaultTrue "crowdsec";
  };

  config.my.containers.services.contents = mkIf cfg.enable {
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

    crowdsec = mkIf cfg.crowdsec.enable (makeDefault {
      image = "crowdsecurity/crowdsec:latest";
      networks = [ "default" "external" ];
      volumes = [
        "${config.my.storage.getConfigPath "crowdsec"}:/etc/crowdsec"
        "${config.my.storage.getLogPath "crowdsec"}:/var/log/nginx"
        "${config.my.storage.getDataPath "crowdsec"}:/var/lib/crowdsec/data"
      ];
    });
  };
}
