{ config, lib, utils, ... }:

with lib;
let
  cfg = config.my.containers.services;
  inherit (utils) makeEnableOptionDefaultTrue makeDefault;
in
{
  options.my.containers.services = {
    audiobookshelf.enable = makeEnableOptionDefaultTrue "audiobookshelf";
    bazarr.enable = makeEnableOptionDefaultTrue "bazarr";
    jackett.enable = makeEnableOptionDefaultTrue "jackett";
    jellyfin.enable = makeEnableOptionDefaultTrue "jellyfin";
    jellyseerr.enable = makeEnableOptionDefaultTrue "jellyseerr";
    lazylibrarian.enable = makeEnableOptionDefaultTrue "lazylibrarian";
    lidarr.enable = makeEnableOptionDefaultTrue "lidarr";
    mylar.enable = makeEnableOptionDefaultTrue "mylar";
    prowlarr.enable = makeEnableOptionDefaultTrue "prowlarr";
    radarr.enable = makeEnableOptionDefaultTrue "radarr";
    readarr.enable = makeEnableOptionDefaultTrue "readarr";
    sonarr.enable = makeEnableOptionDefaultTrue "sonarr";
  };

  config.my.containers.services.contents = mkIf cfg.enable {
    audiobookshelf = mkIf cfg.audiobookshelf.enable (makeDefault {
      image = "ghcr.io/advplyr/audiobookshelf:latest";
      ports = [ "13378:80" ];
      volumes = [
        "${config.my.storage.getConfigPath "audiobookshelf"}:/config"
        "${config.my.storage.getDataPath "audiobookshelf"}:/metadata"
        "${config.my.storage.main}:/storage"
      ];
      networks = [ "default" "external" ];
      labels = {
        "homepage.group" = "Media";
        "homepage.name" = "Audiobookshelf";
        "homepage.icon" = "audiobookshelf.png";
        "homepage.href" = "https://audiobookshelf.${config.my.domain}";
        "homepage.description" = "Audiobook and podcast manager";
        "traefik.enable" = "true";
        "traefik.http.routers.audiobookshelf.entrypoints" = "websecure";
        "traefik.http.routers.audiobookshelf.rule" =
          "Host(`audiobookshelf.${config.my.domain}`)";
        "traefik.http.routers.audiobookshelf.middlewares" = "default@file";
      };
    });

    bazarr = mkIf cfg.bazarr.enable (makeDefault {
      image = "lscr.io/linuxserver/bazarr:latest";
      environment = {
        DOCKER_MODS = "ghcr.io/themepark-dev/theme.park:bazarr";
        TP_DOMAIN = "themepark.${config.my.domain}";
        TP_THEME = "frappe";
      };
      networks = [ "default" "external" ];
      ports = [ "6767:6767" ];
      volumes =
        [ "${config.my.storage.getConfigPath "bazarr"}:/config" "${config.my.storage.main}:/storage" ];
      labels = {
        "homepage.group" = "Media";
        "homepage.name" = "Bazarr";
        "homepage.icon" = "bazarr.png";
        "homepage.href" = "https://bazarr.${config.my.domain}";
        "homepage.description" = "Subtitle manager";
        "homepage.widget.type" = "bazarr";
        "homepage.widget.url" = "https://bazarr.${config.my.domain}";
        "homepage.widget.key" = "\${secret_bazarr_api_key}";
        "traefik.enable" = "true";
        "traefik.http.routers.bazarr.entrypoints" = "websecure";
        "traefik.http.routers.bazarr.rule" = "Host(`bazarr.${config.my.domain}`)";
        "traefik.http.routers.bazarr.middlewares" = "default@file";
      };
    });

    jackett = mkIf cfg.jackett.enable (makeDefault {
      profiles = [ "disable" ];
      image = "lscr.io/linuxserver/jackett";
      networks = [ "default" "external" ];
      ports = [ "9117:9117" ];
      volumes =
        [ "${config.my.storage.getConfigPath "jackett"}:/config" "${config.my.storage.main}:/storage" ];
    });

    jellyfin = mkIf cfg.jellyfin.enable (makeDefault {
      profiles = [ "disable" ];
      image = "lscr.io/linuxserver/jellyfin";
      environment = { DOCKER_MODS = "linuxserver/mods:jellyfin-opencl-intel"; };
      networks = [ "default" "external" ];
      ports = [ "8096:8096" "7359:7359" "1900:1900" ];
      volumes = [ "${config.my.storage.getConfigPath "jellyfin"}:/config" "${config.my.storage.main}:/data" ];
      devices = [ "/dev/dri:/dev/dri" ];
    });

    jellyseerr = mkIf cfg.jellyseerr.enable (makeDefault {
      image = "fallenbagel/jellyseerr:latest";
      networks = [ "default" "external" ];
      ports = [ "5055:5055" ];
      volumes = [ "${config.my.storage.getConfigPath "jellyseerr"}:/app/config" ];
      labels = {
        "homepage.group" = "Media";
        "homepage.name" = "Jellyseerr";
        "homepage.icon" = "jellyseerr.png";
        "homepage.href" = "https://jellyseerr.${config.my.domain}";
        "homepage.description" = "Media requester";
        "homepage.weight" = -80000;
        "homepage.widget.type" = "jellyseerr";
        "homepage.widget.url" = "https://jellyseerr.${config.my.domain}";
        "homepage.widget.key" = "\${secret_jellyseerr_api_key}";
        "traefik.enable" = "true";
        "traefik.http.routers.jellyseerr.entrypoints" = "websecure";
        "traefik.http.routers.jellyseerr.rule" =
          "Host(`jellyseerr.${config.my.domain}`)";
        "traefik.http.routers.jellyseerr.middlewares" = "default@file";
      };
    });

    lazylibrarian = mkIf cfg.lazylibrarian.enable (makeDefault {
      image = "lscr.io/linuxserver/lazylibrarian:latest";
      environment = {
        DOCKER_MODS = "linuxserver/mods:universal-calibre|linuxserver/mods:lazylibrarian-ffmpeg";
      };
      ports = [ "5299:5299" ];
      volumes = [
        "${config.my.storage.getConfigPath "lazylibrarian"}:/config"
        "${config.my.storage.main}:/storage"
      ];
      networks = [ "default" "external" ];
      labels = {
        "homepage.group" = "Media";
        "homepage.name" = "LazyLibrarian";
        "homepage.icon" = "lazylibrarian.png";
        "homepage.href" = "https://lazylibrarian.${config.my.domain}";
        "homepage.description" = "Book manager";
        "traefik.enable" = "true";
        "traefik.http.routers.lazylibrarian.entrypoints" = "websecure";
        "traefik.http.routers.lazylibrarian.rule" =
          "Host(`lazylibrarian.${config.my.domain}`)";
        "traefik.http.routers.lazylibrarian.middlewares" = "default@file";
      };
    });

    lidarr = mkIf cfg.lidarr.enable (makeDefault {
      image = "lscr.io/linuxserver/lidarr:latest";
      ports = [ "8686:8686" ];
      volumes =
        [ "${config.my.storage.getConfigPath "lidarr"}:/config" "${config.my.storage.main}:/storage" ];
      networks = [ "default" "external" ];
      labels = {
        "homepage.group" = "Media";
        "homepage.name" = "Lidarr";
        "homepage.icon" = "lidarr.png";
        "homepage.href" = "https://lidarr.${config.my.domain}";
        "homepage.description" = "Music manager";
        "traefik.enable" = "true";
        "traefik.http.routers.lidarr.entrypoints" = "websecure";
        "traefik.http.routers.lidarr.rule" = "Host(`lidarr.${config.my.domain}`)";
        "traefik.http.routers.lidarr.middlewares" = "default@file";
      };
    });

    mylar = mkIf cfg.mylar.enable (makeDefault {
      profiles = [ "disable" ];
      image = "lscr.io/linuxserver/mylar3:latest";
      ports = [ "8090:8090" ];
      volumes =
        [ "${config.my.storage.getConfigPath "mylar"}:/config" "${config.my.storage.main}:/storage" ];
      networks = [ "default" "external" ];
      labels = {
        "homepage.group" = "Media";
        "homepage.name" = "Mylar";
        "homepage.icon" = "mylar.png";
        "homepage.href" = "https://mylar.${config.my.domain}";
        "homepage.description" = "Comics/Manga manager";
        "traefik.enable" = "true";
        "traefik.http.routers.mylar.entrypoints" = "websecure";
        "traefik.http.routers.mylar.rule" = "Host(`mylar.${config.my.domain}`)";
        "traefik.http.routers.mylar.middlewares" = "default@file";
      };
    });

    prowlarr = mkIf cfg.prowlarr.enable (makeDefault {
      image = "lscr.io/linuxserver/prowlarr:latest";
      environment = {
        DOCKER_MODS = "ghcr.io/themepark-dev/theme.park:prowlarr";
        TP_DOMAIN = "themepark.${config.my.domain}";
        TP_THEME = "frappe";
      };
      networks = [ "default" "external" ];
      ports = [ "9696:9696" ];
      volumes = [ "${config.my.storage.getConfigPath "prowlarr"}:/config" ];
      labels = {
        "homepage.group" = "Media";
        "homepage.name" = "Prowlarr";
        "homepage.icon" = "prowlarr.png";
        "homepage.href" = "https://prowlarr.${config.my.domain}";
        "homepage.description" = "Arr index manager";
        "homepage.widget.type" = "prowlarr";
        "homepage.widget.url" = "https://prowlarr.${config.my.domain}";
        "homepage.widget.key" = "\${secret_prowlarr_api_key}";
        "traefik.enable" = "true";
        "traefik.http.routers.prowlarr.entrypoints" = "websecure";
        "traefik.http.routers.prowlarr.rule" = "Host(`prowlarr.${config.my.domain}`)";
        "traefik.http.routers.prowlarr.middlewares" = "default@file";
      };
    });

    radarr = mkIf cfg.radarr.enable (makeDefault {
      image = "lscr.io/linuxserver/radarr:latest";
      environment = {
        DOCKER_MODS = "ghcr.io/themepark-dev/theme.park:radarr";
        TP_DOMAIN = "themepark.${config.my.domain}";
        TP_THEME = "frappe";
      };
      networks = [ "default" "external" ];
      ports = [ "7878:7878" ];
      volumes =
        [ "${config.my.storage.getConfigPath "radarr"}:/config" "${config.my.storage.main}:/storage" ];
      labels = {
        "homepage.group" = "Media";
        "homepage.name" = "Radarr";
        "homepage.icon" = "radarr.png";
        "homepage.href" = "https://radarr.${config.my.domain}";
        "homepage.description" = "Movie manager";
        "homepage.weight" = -60000;
        "homepage.widget.type" = "radarr";
        "homepage.widget.url" = "https://radarr.${config.my.domain}";
        "homepage.widget.key" = "\${secret_radarr_api_key}";
        "traefik.enable" = "true";
        "traefik.http.routers.radarr.entrypoints" = "websecure";
        "traefik.http.routers.radarr.rule" = "Host(`radarr.${config.my.domain}`)";
        "traefik.http.routers.radarr.middlewares" = "default@file";
      };
    });

    readarr = mkIf cfg.readarr.enable (makeDefault {
      profiles = [ "disable" ];
      image = "lscr.io/linuxserver/readarr:latest";
      ports = [ "8787:8787" ];
      volumes =
        [ "${config.my.storage.getConfigPath "readarr"}:/config" "${config.my.storage.main}:/storage" ];
      networks = [ "default" "external" ];
      labels = {
        "homepage.group" = "Media";
        "homepage.name" = "Readarr";
        "homepage.icon" = "readarr.png";
        "homepage.href" = "https://readarr.${config.my.domain}";
        "homepage.description" = "Book manager";
        "traefik.enable" = "false";
        "traefik.http.routers.readarr.entrypoints" = "websecure";
        "traefik.http.routers.readarr.rule" = "Host(`readarr.${config.my.domain}`)";
        "traefik.http.routers.readarr.middlewares" = "default@file";
      };
    });

    sonarr = mkIf cfg.sonarr.enable (makeDefault {
      image = "lscr.io/linuxserver/sonarr:latest";
      environment = {
        DOCKER_MODS = "ghcr.io/themepark-dev/theme.park:sonarr";
        TP_DOMAIN = "themepark.${config.my.domain}";
        TP_THEME = "frappe";
      };
      networks = [ "default" "external" ];
      ports = [ "8989:8989" ];
      volumes =
        [ "${config.my.storage.getConfigPath "sonarr"}:/config" "${config.my.storage.main}:/storage" ];
      labels = {
        "homepage.group" = "Media";
        "homepage.name" = "Sonarr";
        "homepage.icon" = "sonarr.png";
        "homepage.href" = "https://sonarr.${config.my.domain}";
        "homepage.description" = "Series manager";
        "homepage.weight" = -70000;
        "homepage.widget.type" = "sonarr";
        "homepage.widget.url" = "https://sonarr.${config.my.domain}";
        "homepage.widget.key" = "\${secret_sonarr_api_key}";
        "traefik.enable" = "true";
        "traefik.http.routers.sonarr.entrypoints" = "websecure";
        "traefik.http.routers.sonarr.rule" = "Host(`sonarr.${config.my.domain}`)";
        "traefik.http.routers.sonarr.middlewares" = "default@file";
      };
    });
  };
}
