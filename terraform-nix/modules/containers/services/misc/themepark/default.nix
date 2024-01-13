{ config, inputs, lib, utils, ... }:

with lib;
let
  cfg = config.my.containers.services;
  inherit (utils) makeEnableOptionDefaultTrue makeDefault makeRuntimeAssetsDir;

  name = "themepark";
  configPath = config.my.storage.getConfigPath name;
in
{
  options.my.containers.services.themepark = {
    enable = makeEnableOptionDefaultTrue name;
    catppuccin = {
      enable = mkEnableOption name // { default = true; };
    };
  };

  config = mkIf cfg.themepark.enable (mkMerge [
    {
      my.containers.services.contents = mkIf cfg.enable {
        themepark = mkIf cfg.themepark.enable (makeDefault {
          image = "ghcr.io/themepark-dev/theme.park:latest";
          ports = [ "8084:80" "8444:443" ];
          volumes = [
            "${configPath}:/config"
          ] ++ optionals cfg.themepark.catppuccin.enable (
            map
              (file: "/run/${name}/flavors/${file}:/config/www/css/theme-options/${file}")
              (attrNames (builtins.readDir "${inputs.catppuccin-theme-park}/flavors"))
          );
          labels = {
            "traefik.enable" = "true";
            "traefik.http.routers.themepark.entrypoints" = "websecure";
            "traefik.http.routers.themepark.rule" = "Host(`themepark.${config.my.domain}`)";
            "traefik.http.routers.themepark.middlewares" = "default@file";
            "traefik.http.services.themepark.loadbalancer.server.port" = "80";
          };
        });
      };
    }
    (makeRuntimeAssetsDir {
      inherit name;
      assets = "${inputs.catppuccin-theme-park}";
    })
  ]);
}
