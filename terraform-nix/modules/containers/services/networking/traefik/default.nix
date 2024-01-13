{ config, lib, utils, ... }:

with lib;
let
  cfg = config.my.containers.services;
  inherit (utils) makeAssetsDerivation makeEnableOptionDefaultTrue makeDefault makeRuntimeAssetsDir;

  name = "traefik";
in
{
  options.my.containers.services.traefik = {
    enable = makeEnableOptionDefaultTrue name;
  };

  config = mkIf cfg.traefik.enable (mkMerge [
    {
      my.containers.services.contents.traefik = makeDefault {
        image = "traefik:v2.10";
        environment = { CF_DNS_API_TOKEN = "\${secret_cloudflare_api_token}"; };
        networks = [ "default" "external" ];
        ports = [
          "${builtins.toString config.my.networking.ports.internal.http}:80"
          "${builtins.toString config.my.networking.ports.internal.https}:443"
          "8080:8080"
        ];
        volumes = [
          "/run/${name}:/etc/traefik"
          "${config.my.storage.getConfigPath "traefik"}/acme/acme.json:/etc/traefik/acme/acme.json"
          "/var/run/docker.sock:/var/run/docker.sock"
        ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "false";
        };
      };
    }
    (makeRuntimeAssetsDir {
      inherit name;
      assets = makeAssetsDerivation name ./assets;
      envPath = ../../../../../secrets/docker/default.env;
      extraEnv = {
        domain = config.my.domain;
        trustedIpsCloudflare = concatStringsSep ", " (map (ip: "'${ip}'") config.my.networking.cidrs.cloudflare);
        trustedIpsPrivate = concatStringsSep ", " (map (ip: "'${ip}'") config.my.networking.cidrs.private);
      };
      filesToTemplate = [ "dynamic.yml" "traefik.yml" ];
    })
  ]);
}
