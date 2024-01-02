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
    services.caddy = {
        enable = true;
      virtualHosts."localhost".extraConfig = ''
        respond "Hello, world!"
      '';
    };
  };
}
