# Documentation: https://nixos.wiki/wiki/Caddy

{ config, lib, options, ... }:

let
  cfg = config.my.services.caddy;
in
with lib;
{
  options.my.services.caddy = {
    enable = mkEnableOption "caddy";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 443 ];
    networking.enableIPv6 = true;

    services.caddy = {
        enable = true;
      virtualHosts."localhost".extraConfig = ''
        respond "Hello, world!"
      '';
    };
  };
}
