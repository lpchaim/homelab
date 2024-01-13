{ config, lib, utils, ... }:

with lib;
let
  cfg = config.my.containers.services;
  inherit (utils) makeAssetsDerivation makeEnableOptionDefaultTrue makeDefault makeRuntimeAssetsDir;

  name = "homepage";
in
{
  options.my.containers.services.homepage = {
    enable = makeEnableOptionDefaultTrue name;
    catppuccin = {
      enable = mkEnableOption name // { default = true; };
    };
  };

  config = mkIf cfg.homepage.enable (mkMerge [
    {
      my.containers.services.contents = mkIf cfg.enable {
        homepage = mkIf cfg.homepage.enable (makeDefault {
          image = "ghcr.io/gethomepage/homepage:latest";
          networks = [ "default" "external" ];
          ports = [ "3000:3000" ];
          volumes = [
            "/run/${name}:/app/config"
            "${config.my.storage.main}:/storage:ro"
            "/var/run/docker.sock:/var/run/docker.sock"
          ];
          labels = {
            "traefik.enable" = "true";
            "traefik.http.routers.home.entrypoints" = "websecure";
            "traefik.http.routers.home.rule" = "Host(`home.${config.my.domain}`)";
            "traefik.http.routers.home.middlewares" = "default@file";
          };
        });
      };
    }
    (makeRuntimeAssetsDir {
      inherit name;
      assets = makeAssetsDerivation name ./assets;
      envPath = ../../../../../secrets/docker/default.env;
      extraEnv = { domain = config.my.domain; };
      filesToTemplate = [ "services.yaml" ];
    })
  ]);
}
