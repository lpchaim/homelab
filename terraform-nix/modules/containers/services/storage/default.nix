{ config, lib, utils, ... }:

with lib;
let
  cfg = config.my.containers.services;
  inherit (utils) makeEnableOptionDefaultTrue makeDefault;
in
{
  options.my.containers.services = {
    influxdb.enable = makeEnableOptionDefaultTrue "influxdb";
    qbittorrent.enable = makeEnableOptionDefaultTrue "qbittorrent";
    syncthing.enable = makeEnableOptionDefaultTrue "syncthing";
  };

  config.my.containers.services.contents = mkIf cfg.enable {
    influxdb = mkIf cfg.influxdb.enable (makeDefault {
      image = "influxdb:latest";
      networks = [ "default" "external" ];
      ports = [ "8086:8086" ];
      volumes = [
        "${config.my.storage.getConfigPath "influxdb"}:/etc/influxdb2"
        "${config.my.storage.getDataPath "influxdb"}:/var/lib/influxdb2"
      ];
    });

    qbittorrent = mkIf cfg.qbittorrent.enable (makeDefault {
      image = "lscr.io/linuxserver/qbittorrent:latest";
      environment = {
        WEBUI_PORT = "8081";
        # DOCKER_MODS = "ghcr.io/themepark-dev/theme.park:qbittorrent";
        # TP_DOMAIN = "themepark.${config.my.domain}";
        # TP_THEME = "frappe";
      };
      networks = [ "default" "external" ];
      ports = [ "8081:8081" "6881:6881" "6881:6881/udp" ];
      volumes = [
        "${config.my.storage.getConfigPath "qbittorrent"}:/config"
        "${config.my.storage.main}/Downloads/Torrents:/downloads"
      ];
      labels = {
        "homepage.group" = "Other";
        "homepage.name" = "qBittorrent";
        "homepage.icon" = "qbittorrent.png";
        "homepage.href" = "https://qbittorrent.${config.my.domain}";
        "homepage.description" = "Torrent downloader";
        "homepage.widget.type" = "qbittorrent";
        "homepage.widget.url" = "https://qbittorrent.${config.my.domain}";
        "homepage.widget.username" = "\${secret_qbittorrent_user}";
        "homepage.widget.password" = "\${secret_qbittorrent_password}";
        "traefik.enable" = "true";
        "traefik.http.routers.qbittorrent.entrypoints" = "websecure";
        "traefik.http.routers.qbittorrent.rule" =
          "Host(`qbittorrent.${config.my.domain}`)";
        "traefik.http.routers.qbittorrent.middlewares" = "default@file";
        "traefik.http.services.qbittorrent.loadbalancer.server.port" = "8081";
      };
    });

    syncthing = mkIf cfg.syncthing.enable (makeDefault {
      image = "lscr.io/linuxserver/syncthing:latest";
      networks = [ "default" "external" ];
      ports =
        [ "8384:8384" "22000:22000/tcp" "22000:22000/udp" "21027:21027/udp" ];
      volumes = [
        "${config.my.storage.getConfigPath "syncthing"}:/config"
        "${config.my.storage.getDataPath "syncthing"}:/data"
      ];
      labels = {
        "homepage.group" = "Other";
        "homepage.name" = "Syncthing";
        "homepage.icon" = "syncthing.png";
        "homepage.href" = "https://syncthing.${config.my.domain}";
        "homepage.description" = "P2P file syncing";
        "traefik.enable" = "true";
        "traefik.http.routers.syncthing.entrypoints" = "websecure";
        "traefik.http.routers.syncthing.rule" = "Host(`syncthing.${config.my.domain}`)";
        "traefik.http.routers.syncthing.middlewares" = "default@file";
        "traefik.http.services.syncthing.loadbalancer.server.port" = "8384";
      };
    });
  };
}
