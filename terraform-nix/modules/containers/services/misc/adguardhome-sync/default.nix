{ config, lib, utils, ... }:

with lib;
let
  cfg = config.my.containers.services;
  inherit (utils) makeAssetsDerivation makeEnableOptionDefaultTrue makeDefault makeRuntimeAssetsDir;

  name = "adguardhome-sync";
in
{
  options.my.containers.services.adguardhome-sync.enable = makeEnableOptionDefaultTrue name;

  config = mkIf cfg.adguardhome-sync.enable (mkMerge [
    {
      my.containers.services.contents = mkIf cfg.enable {
        adguardhome-sync = mkIf cfg.adguardhome-sync.enable (makeDefault {
          image = "lscr.io/linuxserver/adguardhome-sync:latest";
          ports = [ "8082:8082/tcp" ];
          volumes = [
            "/run/${name}/adguardhome-sync.yaml:/config/adguardhome-sync.yaml"
          ];
        });
      };
    }
    (makeRuntimeAssetsDir {
      inherit name;
      assets = makeAssetsDerivation name ./assets;
      envPath = ../../../../../secrets/docker/default.env;
      filesToTemplate = [ "adguardhome-sync.yaml" ];
      postExec = optionalString config.my.containers.instrumentation.compose.enable ''
        docker compose --file ~/compose.yaml restart ${name}
      '';
    })
  ]);
}
