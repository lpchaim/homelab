{ config, lib, ... }:

with lib;
{
  makeEnableOptionDefaultTrue = name: mkEnableOption name // { default = true; };
  makeDefault = dockerConfig:
    (dockerConfig // {
      environment = {
        TZ = config.my.timezone;
        PUID = 1000;
        GUID = 1000;
      } // (dockerConfig.environment or {});
      volumes = [
        "/dev/rtc:/dev/rtc:ro"
        "/etc/localtime:/etc/localtime:ro"
        "/etc/timezone:/etc/timezone:ro"
      ] ++ (dockerConfig.volumes or []);
      restart = dockerConfig.restart or "unless-stopped";
    });
}
