# Documentation: https://nixos.wiki/wiki/Docker

{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.services.docker;
in
with lib;
{
  options.my.services.docker = {
    enable = mkEnableOption "docker";
  };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      autoPrune = {
        enable = true;
        flags = [ "--all" "--force" ];
        dates = "weekly";
      };
    };

    system.activationScripts = {
      docker-socket-perms.text = toString (pkgs.writers.writeBash "docker-socket-perms" ''
        chmod o+rw /var/run/docker.sock
      '');
    };
  };
}
