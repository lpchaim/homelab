{ config, ports, ... }:

let
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
in
{
  name = "homelab";
  version = "3.6";

  services = {
    cloudflare-ddns = makeDefault {
      image = "oznu/cloudflare-ddns:latest";
      environment = {
        API_KEY = "\${secret_cloudflare_api_token}";
        ZONE = config.my.domain;
        INTERFACE = "eth0";
        PROXIED = "true";
        RRTYPE = "AAAA";
      };
      network_mode = "host";
    };

    crowdsec = makeDefault {
      image = "crowdsecurity/crowdsec:latest";
      networks = [ "default" "external" ];
      volumes = [
        "${config.my.storage.getConfigPath "crowdsec"}:/etc/crowdsec"
        "${config.my.storage.getLogPath "crowdsec"}:/var/log/nginx"
        "${config.my.storage.getDataPath "crowdsec"}:/var/lib/crowdsec/data"
      ];
    };

    themepark = makeDefault {
      image = "ghcr.io/themepark-dev/theme.park:latest";
      ports = [ "8084:80" "8444:443" ];
      volumes = [ "${config.my.storage.getConfigPath "themepark"}:/config" ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.themepark.entrypoints" = "websecure";
        "traefik.http.routers.themepark.rule" = "Host(`themepark.${config.my.domain}`)";
        "traefik.http.routers.themepark.middlewares" = "default@file";
        "traefik.http.services.themepark.loadbalancer.server.port" = "80";
      };
    };

    traefik = makeDefault {
      image = "traefik:v2.10";
      environment = { CF_DNS_API_TOKEN = "\${secret_cloudflare_api_token}"; };
      networks = [ "default" "external" ];
      ports = [
        "${builtins.toString ports.internal.http}:80"
        "${builtins.toString ports.internal.https}:443"
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
    };

    audiobookshelf = makeDefault {
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
    };

    bazarr = makeDefault {
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
    };

    lazylibrarian = makeDefault {
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
    };

    lidarr = makeDefault {
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
    };

    mylar = makeDefault {
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
    };

    radarr = makeDefault {
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
    };

    readarr = makeDefault {
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
    };

    sonarr = makeDefault {
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
    };

    jellyseerr = makeDefault {
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
    };

    prowlarr = makeDefault {
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
    };

    actual-server = makeDefault {
      image = "actualbudget/actual-server:latest";
      networks = [ "default" "external" ];
      ports = [ "5006:5006" ];
      volumes = [ "${config.my.storage.getDataPath "actual-server"}:/data" ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.actual.entrypoints" = "websecure";
        "traefik.http.routers.actual.rule" = "Host(`actual.${config.my.domain}`)";
        "traefik.http.routers.actual.middlewares" = "default@file";
      };
    };

    adguardhome-sync = makeDefault {
      image = "lscr.io/linuxserver/adguardhome-sync:latest";
      ports = [ "8082:8082/tcp" ];
      volumes = [ "${config.my.storage.getConfigPath "adguardhome-sync"}:/config" ];
    };

    homepage = makeDefault {
      image = "ghcr.io/gethomepage/homepage:latest";
      networks = [ "default" "external" ];
      ports = [ "3000:3000" ];
      volumes = [
        "${config.my.storage.getConfigPath "homepage"}:/app/config"
        "${config.my.storage.main}:/storage:ro"
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.home.entrypoints" = "websecure";
        "traefik.http.routers.home.rule" = "Host(`home.${config.my.domain}`)";
        "traefik.http.routers.home.middlewares" = "default@file";
      };
    };

    forgejo-server = makeDefault {
      image = "codeberg.org/forgejo/forgejo:1.20";
      environment = {
        USER_UID = 1000;
        USER_GID = 1000;
        FORGEJO__actions__ENABLED = "true";
        FORGEJO__database__DB_TYPE = "postgres";
        FORGEJO__database__HOST = "forgejo-db:5432";
        FORGEJO__database__NAME = "forgejo";
        FORGEJO__database__USER = "forgejo";
        FORGEJO__database__PASSWD = "\${secret_forgejo_db_password}";
        FORGEJO__mailer__ENABLED = "true";
        FORGEJO__mailer__FROM = "forgejo@${config.my.domain}";
        FORGEJO__mailer__PROTOCOL = "starttls";
        FORGEJO__mailer__SMTP_ADDR = "\${secret_smtp_host}";
        FORGEJO__mailer__SMTP_PORT = "\${secret_smtp_port}";
        FORGEJO__mailer__USER = "\${secret_smtp_user}";
        FORGEJO__mailer__PASSWD = "\${secret_smtp_password}";
        FORGEJO__service__DISABLE_REGISTRATION = "true";
        FORGEJO__service__REGISTER_MANUAL_CONFIRM = "true";
      };
      networks = [ "default" "external" ];
      ports = [ "3001:3000" "222:22" ];
      volumes = [ "${config.my.storage.getDataPath "forgejo-server"}:/data" ];
      labels = {
        "com.centurylinklabs.watchtower.enable" = "false";
        "homepage.group" = "Other";
        "homepage.name" = "Forgejo";
        "homepage.icon" = "forgejo.png";
        "homepage.href" = "https://git.${config.my.domain}";
        "homepage.description" = "Code forge";
        "traefik.enable" = "true";
        "traefik.http.routers.git.entrypoints" = "websecure";
        "traefik.http.routers.git.rule" = "Host(`git.${config.my.domain}`)";
        "traefik.http.routers.git.middlewares" = "default@file";
        "traefik.http.services.git.loadbalancer.server.port" = "3000";
      };
      depends_on = [ "forgejo-db" ];
    };

    forgejo-db = makeDefault {
      image = "postgres:14";
      environment = {
        POSTGRES_USER = "forgejo";
        POSTGRES_PASSWORD = "\${secret_forgejo_db_password}";
        POSTGRES_DB = "forgejo";
      };
      networks = [ "default" ];
      volumes = [ "${config.my.storage.getDataPath "forgejo-postgres"}:/var/lib/postgresql/data" ];
      labels = {
        "com.centurylinklabs.watchtower.enable" = "false";
      };
    };

    influxdb = makeDefault {
      image = "influxdb:latest";
      networks = [ "default" "external" ];
      ports = [ "8086:8086" ];
      volumes = [
        "${config.my.storage.getConfigPath "influxdb"}:/etc/influxdb2"
        "${config.my.storage.getDataPath "influxdb"}:/var/lib/influxdb2"
      ];
    };

    jackett = makeDefault {
      profiles = [ "disable" ];
      image = "lscr.io/linuxserver/jackett";
      networks = [ "default" "external" ];
      ports = [ "9117:9117" ];
      volumes =
        [ "${config.my.storage.getConfigPath "jackett"}:/config" "${config.my.storage.main}:/storage" ];
    };

    jellyfin = makeDefault {
      profiles = [ "disable" ];
      image = "lscr.io/linuxserver/jellyfin";
      environment = { DOCKER_MODS = "linuxserver/mods:jellyfin-opencl-intel"; };
      networks = [ "default" "external" ];
      ports = [ "8096:8096" "7359:7359" "1900:1900" ];
      volumes = [ "${config.my.storage.getConfigPath "jellyfin"}:/config" "${config.my.storage.main}:/data" ];
      devices = [ "/dev/dri:/dev/dri" ];
    };

    qbittorrent = makeDefault {
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
    };

    syncthing = makeDefault {
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
    };

    vscode = makeDefault {
      image = "lscr.io/linuxserver/code-server:latest";
      environment = {
        PASSWORD = "\${secret_vscode_password}";
        PROXY_DOMAIN = "code.${config.my.domain}";
      };
      networks = [ "default" "external" ];
      ports = [ "8443:8443/tcp" ];
      volumes = [ "${config.my.storage.getConfigPath "vscode"}:/config" ];
      labels = {
        "homepage.group" = "Other";
        "homepage.name" = "Visual Studio Code";
        "homepage.icon" = "vscode.png";
        "homepage.href" = "https://code.${config.my.domain}";
        "homepage.description" = "Cloud IDE";
        "traefik.enable" = "true";
        "traefik.http.routers.code.entrypoints" = "websecure";
        "traefik.http.routers.code.rule" = "Host(`code.${config.my.domain}`)";
        "traefik.http.routers.code.middlewares" = "default@file";
      };
    };

    portainer = makeDefault {
      image = "portainer/portainer-ce:latest";
      network_mode = "bridge";
      ports = [ "8001:8000" "9443:9443" ];
      restart = "always";
      volumes = [
        "${config.my.storage.getDataPath "portainer"}:/data"
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
    };

    watchtower = makeDefault {
      image = "containrrr/watchtower:latest";
      networks = [ "default" "external" ];
      environment = {
        WATCHTOWER_SCHEDULE = "0 2 * * *";
        WATCHTOWER_CLEANUP = "true";
      };
      restart = "unless-stopped";
      volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
    };

    yacht = makeDefault {
      image = "selfhostedpro/yacht:latest";
      networks = [ "default" "external" ];
      ports = [ "8000:8000" ];
      volumes = [
        "${config.my.storage.getConfigPath "yacht"}:/config"
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
    };
  };

  networks = {
    default = {
      internal = true;
      ipam.config = [{ subnet = "172.16.80.0/24"; }];
    };

    external.ipam.config = [{ subnet = "10.10.250.0/24"; }];
  };
}
