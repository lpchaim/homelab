# Documentation: https://nixos.wiki/wiki/Traefik

{ config, inputs, lib, options, pkgs, system, ... }:

let
  cfg = config.my.services.crowdsec;
  myCfg = config.my;
in
with lib;
{
  options.my.services.crowdsec = {
    enable = mkEnableOption "crowdsec";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      crowdsec
    ];

    systemd.services.crowdsec = {
      enable = true;
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" "crowdsec.service" ];
      startLimitIntervalSec = 86400;
      startLimitBurst = 5;
      serviceConfig = {
        ExecStart = "${pkgs.crowdsec}/bin/crowdsec";
        ExecStartPre = pkgs.writeShellScript "pre-start" ''
          umask 077
          mkdir -p /var/lib/crowdsec/data
        '';
        Type = "simple";
        User = "crowdsec";
        Group = "crowdsec";
        Restart = "on-failure";
        AmbientCapabilities = "cap_net_bind_service";
        CapabilityBoundingSet = "cap_net_bind_service";
        NoNewPrivileges = true;
        LimitNPROC = 64;
        LimitNOFILE = 1048576;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHome = true;
        ProtectSystem = "full";
        ReadWriteDirectories = "/var/lib/crowdsec";
        RuntimeDirectory = "crowdsec";
      };
    };

    users.users.crowdsec = {
      group = "crowdsec";
      uid = 1000;
      isSystemUser = true;
    };
    users.groups.crowdsec.gid = 1000;
  };
}
