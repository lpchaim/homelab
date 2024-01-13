{ config, lib, utils, ... }:

with lib;
let
  cfg = config.my.containers.services;
  inherit (utils) makeEnableOptionDefaultTrue makeDefault;
in
{
  options.my.containers.services = {
    portainer.enable = makeEnableOptionDefaultTrue "portainer";
    watchtower.enable = makeEnableOptionDefaultTrue "watchtower";
    yacht.enable = makeEnableOptionDefaultTrue "yacht";
  };

  config.my.containers.services.contents = mkIf cfg.enable {
    portainer = mkIf cfg.portainer.enable (makeDefault {
      image = "portainer/portainer-ce:latest";
      network_mode = "bridge";
      ports = [ "8001:8000" "9443:9443" ];
      restart = "always";
      volumes = [
        "${config.my.storage.getDataPath "portainer"}:/data"
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
    });

    watchtower = mkIf cfg.watchtower.enable (makeDefault {
      image = "containrrr/watchtower:latest";
      networks = [ "default" "external" ];
      environment = {
        WATCHTOWER_SCHEDULE = "0 2 * * *";
        WATCHTOWER_CLEANUP = "true";
      };
      restart = "unless-stopped";
      volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
    });

    yacht = mkIf cfg.yacht.enable (makeDefault {
      image = "selfhostedpro/yacht:latest";
      networks = [ "default" "external" ];
      ports = [ "8000:8000" ];
      volumes = [
        "${config.my.storage.getConfigPath "yacht"}:/config"
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
    });
  };
}
