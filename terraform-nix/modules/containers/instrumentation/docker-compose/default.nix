{ config, lib, pkgs, ... }@args:

with lib;
let
  cfg = config.my.containers.instrumentation.compose;

  user = config.users.users.root;

  composeNix = import ./compose.nix args;
  composeFile = pkgs.runCommand "compose-nix-to-yaml"
    {
      buildInputs = [ pkgs.remarshal ];
      preferLocalBuild = true;
    } ''
    remarshal -if json -of yaml \
      < ${
        pkgs.writeText "compose.nix"
        (builtins.toJSON composeNix)
      } \
      > $out
  '';
in
with lib;
{
  options.my.containers.instrumentation.compose = {
    enable = mkEnableOption "docker compose";
  };

  config = mkIf cfg.enable {
    sops = {
      secrets."docker.env" = {
        sopsFile = ../../../../secrets/docker/default.env;
        owner = user.name;
        path = "${user.home}/.env";
      };
    };

    networking.enableIPv6 = true;
    networking.firewall =
      let
        allPorts = builtins.foldl'
          (acc: curr: acc ++ (curr.ports or [ ]))
          [ ]
          (builtins.attrValues composeNix.services);
        rawUdpPorts = filter (port: hasInfix "udp" (toLower port)) allPorts;
        rawTcpPorts = filter (port: ! builtins.elem port rawUdpPorts) allPorts;
        sanitizePorts = ports: lib.unique (map
          (port: pipe port [
            (port: splitString ":" (builtins.toString port))
            builtins.head
            strings.toInt
          ])
          ports);
      in
      {
        enable = true;
        allowedTCPPorts = sanitizePorts ([ 80 443 ] ++ rawTcpPorts);
        allowedUDPPorts = sanitizePorts rawUdpPorts;
      };

    system.activationScripts = {
      docker-compose-cp.text = toString (pkgs.writers.writeBash "docker-compose-cp" ''
        cp -r ${composeFile} ${user.home}/compose.yaml
      '');
      docker-compose-up.text = toString (pkgs.writers.writeBash "docker-compose-up" ''
        cd ${user.home} && ${pkgs.docker}/bin/docker compose up \
          --detach \
          --remove-orphans
      '');
    };

    # Services to tunnel ipv6 traffic to ipv4
    systemd.services =
      let
        make6to4Service = sourcePort: destPort: {
          enable = true;
          after = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          startLimitIntervalSec = 86400;
          startLimitBurst = 5;
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.socat}/bin/socat TCP6-LISTEN:${builtins.toString sourcePort},fork TCP4:127.0.0.1:${builtins.toString destPort}";
            Restart = "on-failure";
            User = "socat";
            Group = "socat";
            AmbientCapabilities = "cap_net_bind_service";
            CapabilityBoundingSet = "cap_net_bind_service";
          };
        };
      in
      {
        "6to4-http" = make6to4Service 80 config.my.networking.ports.internal.http;
        "6to4-https" = make6to4Service 443 config.my.networking.ports.internal.https;
      };

    users.users.socat = {
      group = "socat";
      isSystemUser = true;
    };
    users.groups.socat = { };

    # Misc adjustments
    environment.etc."timezone".text = config.my.timezone;
  };
}
