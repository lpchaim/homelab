{ config, lib, utils, ... }@args:

with lib;
let
  cfg = config.my.containers.services;
  inherit (utils) makeEnableOptionDefaultTrue makeDefault;
in
{
  imports = [
    (import ./adguardhome-sync args)
  ];

  options.my.containers.services = {
    actual-server.enable = makeEnableOptionDefaultTrue "actual-server";
    forgejo.enable = makeEnableOptionDefaultTrue "forgejo";
    homepage.enable = makeEnableOptionDefaultTrue "homepage";
    themepark.enable = makeEnableOptionDefaultTrue "themepark";
    vscode.enable = makeEnableOptionDefaultTrue "vscode";
  };

  config.my.containers.services.contents = mkIf cfg.enable {
    actual-server = mkIf cfg.actual-server.enable (makeDefault {
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
    });

    forgejo-server = mkIf cfg.forgejo.enable (makeDefault {
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
    });

    forgejo-db = mkIf cfg.forgejo.enable (makeDefault {
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
    });

    homepage = mkIf cfg.homepage.enable (makeDefault {
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
    });

    themepark = mkIf cfg.themepark.enable (makeDefault {
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
    });

    vscode = mkIf cfg.vscode.enable (makeDefault {
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
    });
  };
}
